import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/entities/import_result.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/import_schedule/domain/services/import_diagnostic_logger.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_state.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

/// Cubit managing the CSV-only timetable import lifecycle.
///
/// Pipeline:
/// Select CSV (.csv only) -> UTF-8/BOM Decoding -> CsvTimetableParser ->
/// Canonical Candidates -> Conflict & Duplicate Detection -> Interactive Review -> Drift DB Persistence.
class ImportScheduleCubit extends Cubit<ImportScheduleState> {
  final CsvTimetableParser csvParser;
  final ScheduleRepository scheduleRepository;
  final ReminderScheduler? reminderScheduler;

  ImportScheduleCubit({
    CsvTimetableParser? csvParser,
    required this.scheduleRepository,
    this.reminderScheduler,
  }) : csvParser = csvParser ?? CsvTimetableParser(),
       super(const ImportScheduleState());

  /// Pick a CSV document with standard timetable headers (.csv only)
  Future<void> pickAndProcessCsv() async {
    try {
      emit(state.copyWith(status: ImportStatus.picking, clearError: true));

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        emit(state.copyWith(status: ImportStatus.initial));
        return;
      }

      final file = result.files.first;
      final fileName = file.name;

      // Validate file extension explicitly
      final extension = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';
      if (extension != 'csv') {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage:
                'Unsupported file format ($fileName). Only .csv files are supported.',
          ),
        );
        return;
      }

      String csvText = '';
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        csvText = _decodeBytes(file.bytes!);
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          final rawBytes = await ioFile.readAsBytes();
          csvText = _decodeBytes(rawBytes);
        }
      }

      if (csvText.trim().isEmpty) {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage:
                'The selected CSV file is empty or could not be read.',
          ),
        );
        return;
      }

      await processCsvContent(
        csvText,
        fileName: file.name,
        filePath: file.path,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Failed to pick or parse CSV document: ${e.toString()}',
        ),
      );
    }
  }

  /// Process a CSV file by path, enforcing .csv extension
  Future<void> processCsvFile(String filePath) async {
    try {
      emit(state.copyWith(status: ImportStatus.picking, clearError: true));

      final ioFile = File(filePath);
      final fileName = filePath.split(Platform.pathSeparator).last;
      final extension = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';

      if (extension != 'csv') {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage:
                'Unsupported file format ($fileName). Only .csv files are supported.',
          ),
        );
        return;
      }

      if (!await ioFile.exists()) {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage: 'File not found at $filePath',
          ),
        );
        return;
      }

      final bytes = await ioFile.readAsBytes();
      final csvText = _decodeBytes(bytes);

      if (csvText.trim().isEmpty) {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage:
                'The selected CSV file is empty or could not be read.',
          ),
        );
        return;
      }

      await processCsvContent(csvText, fileName: fileName, filePath: filePath);
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Failed to read CSV file: ${e.toString()}',
        ),
      );
    }
  }

  /// Process raw CSV timetable content directly
  Future<void> processCsvContent(
    String csvText, {
    String? fileName,
    String? filePath,
  }) async {
    emit(
      state.copyWith(
        status: ImportStatus.processing,
        processingMessage: 'Analyzing CSV timetable...',
        sourceFileName: fileName ?? 'Timetable.csv',
        sourceFilePath: filePath,
        clearError: true,
      ),
    );

    try {
      final existingLectures = await scheduleRepository.getAllLectures();
      final parsed = await compute(_parseCsvInIsolate, csvText);

      ImportDiagnosticLogger.log(
        'parseCsv:result',
        metadata: {
          'csvLength': csvText.length,
          'parsedRows': parsed.length,
          'validCount': parsed.where((c) => c.isValid).length,
        },
      );

      if (parsed.isEmpty) {
        ImportDiagnosticLogger.log(
          'parseCsv:rejected',
          metadata: {
            'reason':
                'Could not identify timetable columns. Expected headers: Weekday, Course Name, Start Time, End Time, Instructor, Room',
            'csvLength': csvText.length,
          },
        );
      }

      final evaluated = _evaluateCandidates(parsed, existingLectures);

      emit(
        state.copyWith(
          status: ImportStatus.review,
          rawExtractedText: csvText,
          candidates: evaluated,
          existingLectures: existingLectures,
          clearProcessingMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'CSV parsing failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Decodes bytes supporting UTF-8 (with optional BOM) and Latin-1 fallback
  static String _decodeBytes(List<int> bytes) {
    if (bytes.isEmpty) return '';
    try {
      // utf8.decode handles UTF-8 characters cleanly
      var text = utf8.decode(bytes);
      // Strip UTF-8 BOM if present
      if (text.startsWith('\uFEFF')) {
        text = text.substring(1);
      }
      return text;
    } catch (_) {
      // Fallback to latin1 for legacy encodings
      return latin1.decode(bytes);
    }
  }

  /// Update candidate by matching candidate index
  void updateCandidate(int index, ExtractedLectureCandidate updated) {
    if (index < 0 || index >= state.candidates.length) return;

    final updatedList = List<ExtractedLectureCandidate>.from(state.candidates);
    updatedList[index] = updated;

    final reEvaluated = _evaluateCandidates(
      updatedList,
      state.existingLectures,
    );
    emit(state.copyWith(candidates: reEvaluated));
  }

  /// Update candidate by id
  void updateCandidateById(String id, ExtractedLectureCandidate updated) {
    final index = state.candidates.indexWhere((c) => c.id == id);
    if (index != -1) {
      updateCandidate(index, updated);
    }
  }

  /// Remove candidate at index
  void removeCandidate(int index) {
    if (index < 0 || index >= state.candidates.length) return;

    final updatedList = List<ExtractedLectureCandidate>.from(state.candidates);
    updatedList.removeAt(index);

    final reEvaluated = _evaluateCandidates(
      updatedList,
      state.existingLectures,
    );
    emit(state.copyWith(candidates: reEvaluated));
  }

  /// Remove candidate by id
  void removeCandidateById(String id) {
    final index = state.candidates.indexWhere((c) => c.id == id);
    if (index != -1) {
      removeCandidate(index);
    }
  }

  /// Add a specific candidate
  void addCandidate(ExtractedLectureCandidate candidate) {
    final updatedList = List<ExtractedLectureCandidate>.from(state.candidates)
      ..add(candidate);
    final reEvaluated = _evaluateCandidates(
      updatedList,
      state.existingLectures,
    );
    emit(state.copyWith(candidates: reEvaluated));
  }

  /// Cancel any processing in progress
  void cancelProcessing() {
    emit(
      state.copyWith(
        status: ImportStatus.initial,
        clearProcessingMessage: true,
        clearError: true,
      ),
    );
  }

  /// Add a manual candidate for any missing lecture
  void addManualCandidate() {
    final newCandidate = ExtractedLectureCandidate(
      id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
      courseName: '',
      dayOfWeek: 0, // Sunday
      startTime: '09:00',
      endTime: '10:30',
    );

    addCandidate(newCandidate);
  }

  /// Confirm and save all valid candidates to local SQLite database
  Future<void> confirmImport({bool skipDuplicates = true}) async {
    if (state.candidates.isEmpty) return;

    final invalidCandidates = state.candidates
        .where((c) => !c.isValid)
        .toList();
    if (invalidCandidates.isNotEmpty) {
      emit(
        state.copyWith(
          errorMessage:
              'Please correct or remove ${invalidCandidates.length} incomplete lecture(s) before importing.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ImportStatus.saving,
        processingMessage: 'Saving lectures to local database...',
        clearError: true,
      ),
    );

    try {
      final savedLectures = <LectureEntity>[];
      var skippedDuplicates = 0;
      var failed = 0;

      // Re-fetch latest DB lectures for atomic concurrency check
      final latestExisting = await scheduleRepository.getAllLectures();

      for (final candidate in state.candidates) {
        if (!candidate.isValid) {
          failed++;
          continue;
        }

        // Check if duplicate of already existing lecture
        final isDup = latestExisting.any((e) => candidate.isDuplicateOf(e));
        if (isDup && skipDuplicates) {
          skippedDuplicates++;
          continue;
        }

        final entity = candidate.toLectureEntity();
        try {
          final id = await scheduleRepository.addLecture(entity);
          final savedLecture = entity.copyWith(id: id);
          savedLectures.add(savedLecture);
          await reminderScheduler?.scheduleLectureReminder(savedLecture);
        } catch (_) {
          failed++;
        }
      }

      final result = ImportResult(
        importedCount: savedLectures.length,
        skippedDuplicatesCount: skippedDuplicates,
        failedCount: failed,
        importedLectures: savedLectures,
        isSuccess:
            savedLectures.isNotEmpty || (skippedDuplicates > 0 && failed == 0),
        message:
            'Successfully imported ${savedLectures.length} lecture(s).${skippedDuplicates > 0 ? ' Skipped $skippedDuplicates duplicate(s).' : ''}',
      );

      emit(
        state.copyWith(
          status: ImportStatus.success,
          result: result,
          clearProcessingMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Database import failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const ImportScheduleState());
  }

  List<ExtractedLectureCandidate> _evaluateCandidates(
    List<ExtractedLectureCandidate> candidates,
    List<LectureEntity> existingLectures,
  ) {
    final result = <ExtractedLectureCandidate>[];

    for (int i = 0; i < candidates.length; i++) {
      final current = candidates[i];

      // 1. Check duplicate against existing DB lectures
      final isDuplicate =
          current.isDuplicate ||
          existingLectures.any((e) => current.isDuplicateOf(e));

      // 2. Check overlap against existing DB lectures
      LectureEntity? dbConflict;
      for (final existing in existingLectures) {
        if (current.overlapsWithLecture(existing)) {
          dbConflict = existing;
          break;
        }
      }

      // 3. Check overlap against other candidates in this import batch
      ExtractedLectureCandidate? batchConflict;
      for (int j = 0; j < candidates.length; j++) {
        if (i == j) continue;
        if (current.overlapsWith(candidates[j])) {
          batchConflict = candidates[j];
          break;
        }
      }

      final hasConflict =
          current.hasConflict || dbConflict != null || batchConflict != null;
      String? reason = current.conflictReason;
      if (dbConflict != null) {
        reason =
            'Overlaps with existing class: ${dbConflict.courseName} (${dbConflict.startTime} - ${dbConflict.endTime})';
      } else if (batchConflict != null) {
        reason =
            'Overlaps with: ${batchConflict.courseName.isNotEmpty ? batchConflict.courseName : "another lecture"} (${batchConflict.startTime} - ${batchConflict.endTime})';
      }

      result.add(
        current.copyWith(
          isDuplicate: isDuplicate,
          hasConflict: hasConflict,
          conflictReason: reason,
          clearConflict: !hasConflict,
        ),
      );
    }

    return result;
  }
}

/// Standalone top-level function for background CSV isolate execution via compute().
List<ExtractedLectureCandidate> _parseCsvInIsolate(String csvContent) {
  final parser = CsvTimetableParser();
  return parser.parseToCandidates(csvContent);
}
