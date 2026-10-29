import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/entities/import_result.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/import_schedule/domain/services/import_diagnostic_logger.dart';
import 'package:taskora/features/import_schedule/domain/services/text_extractor_service.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_state.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class ImportScheduleCubit extends Cubit<ImportScheduleState> {
  final TextExtractorService textExtractor;
  final TimetableParser parser;
  final ScheduleRepository scheduleRepository;
  final ImagePicker _imagePicker;

  ImportScheduleCubit({
    required this.textExtractor,
    required this.parser,
    required this.scheduleRepository,
    ImagePicker? imagePicker,
  }) : _imagePicker = imagePicker ?? ImagePicker(),
       super(const ImportScheduleState());

  /// Pick an image from gallery or camera and extract lecture candidates
  Future<void> pickAndProcessImage(ImageSource source) async {
    try {
      emit(state.copyWith(status: ImportStatus.picking, clearError: true));

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 95,
      );

      if (pickedFile == null) {
        emit(state.copyWith(status: ImportStatus.initial));
        return;
      }

      await _processFile(
        filePath: pickedFile.path,
        fileName: pickedFile.name,
        isImage: true,
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Failed to process image: ${e.toString()}',
        ),
      );
    }
  }

  /// Pick a PDF document and extract lecture candidates
  Future<void> pickAndProcessPdf() async {
    try {
      emit(state.copyWith(status: ImportStatus.picking, clearError: true));

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        emit(state.copyWith(status: ImportStatus.initial));
        return;
      }

      final file = result.files.first;
      final path = file.path;
      if (path == null) {
        emit(
          state.copyWith(
            status: ImportStatus.failure,
            errorMessage: 'Cannot access the selected PDF file path.',
          ),
        );
        return;
      }

      await _processFile(filePath: path, fileName: file.name, isImage: false);
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Failed to pick or read PDF document: ${e.toString()}',
        ),
      );
    }
  }

  /// Pick a CSV document with standard timetable headers
  Future<void> pickAndProcessCsv() async {
    try {
      emit(state.copyWith(status: ImportStatus.picking, clearError: true));

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'txt'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        emit(state.copyWith(status: ImportStatus.initial));
        return;
      }

      final file = result.files.first;
      String csvText = '';

      if (file.bytes != null && file.bytes!.isNotEmpty) {
        try {
          csvText = utf8.decode(file.bytes!);
        } catch (_) {
          csvText = latin1.decode(file.bytes!);
        }
      } else if (file.path != null) {
        final ioFile = File(file.path!);
        if (await ioFile.exists()) {
          try {
            csvText = await ioFile.readAsString();
          } catch (_) {
            final rawBytes = await ioFile.readAsBytes();
            csvText = latin1.decode(rawBytes);
          }
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

  /// Process direct raw text (e.g., from unit tests or pasted input)
  Future<void> processRawText(String text, {String? fileName}) async {
    emit(
      state.copyWith(
        status: ImportStatus.processing,
        processingMessage: 'Analyzing timetable text...',
        sourceFileName: fileName ?? 'Pasted Timetable',
        clearError: true,
      ),
    );

    try {
      final existingLectures = await scheduleRepository.getAllLectures();
      final parsed = await compute(_parseScheduleInIsolate, text);
      final evaluated = _evaluateCandidates(parsed, existingLectures);

      emit(
        state.copyWith(
          status: ImportStatus.review,
          rawExtractedText: text,
          candidates: evaluated,
          existingLectures: existingLectures,
          clearProcessingMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Failed to parse text: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _processFile({
    required String filePath,
    required String fileName,
    required bool isImage,
  }) async {
    emit(
      state.copyWith(
        status: ImportStatus.processing,
        processingMessage: isImage
            ? 'Extracting text with on-device OCR...'
            : 'Extracting selectable text from PDF...',
        sourceFileName: fileName,
        sourceFilePath: filePath,
        isImage: isImage,
      ),
    );

    try {
      final String extractedText;
      if (isImage) {
        extractedText = await textExtractor.extractTextFromImage(filePath);
      } else {
        extractedText = await textExtractor.extractTextFromPdf(filePath);
      }

      emit(
        state.copyWith(
          processingMessage: 'Analyzing and parsing lecture schedule...',
        ),
      );

      final existingLectures = await scheduleRepository.getAllLectures();
      final parsed = await compute(_parseScheduleInIsolate, extractedText);

      ImportDiagnosticLogger.log(
        'parseSchedule:result',
        metadata: {
          'extractedLength': extractedText.length,
          'parsedRows': parsed.length,
          'validCount': parsed.where((c) => c.isValid).length,
        },
      );

      // Development-only diagnostic logging of candidate validation status
      if (kDebugMode) {
        for (var i = 0; i < parsed.length; i++) {
          final c = parsed[i];
          ImportDiagnosticLogger.log(
            'candidate:inspected',
            metadata: {
              'index': i,
              'course': c.courseName,
              'day': c.dayOfWeek,
              'time': '${c.startTime}-${c.endTime}',
              'room': c.room,
              'inst': c.instructor,
              'isValid': c.isValid,
              if (!c.isValid) 'errors': c.validationErrors,
            },
          );
        }
      }

      if (parsed.isEmpty) {
        ImportDiagnosticLogger.log(
          'parseSchedule:rejected',
          metadata: {
            'reason':
                'Could not automatically identify timetable entries or time ranges in document',
            'extractedLength': extractedText.length,
          },
        );
      }

      final evaluated = _evaluateCandidates(parsed, existingLectures);

      emit(
        state.copyWith(
          status: ImportStatus.review,
          rawExtractedText: extractedText,
          candidates: evaluated,
          existingLectures: existingLectures,
          clearProcessingMessage: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ImportStatus.failure,
          errorMessage: 'Extraction failed: ${e.toString()}',
        ),
      );
    }
  }

  /// Update candidate by matching candidate ID or index
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
          savedLectures.add(entity.copyWith(id: id));
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

/// Standalone top-level function for background isolate execution via compute().
List<ExtractedLectureCandidate> _parseScheduleInIsolate(String text) {
  final parser = TimetableParser();
  return parser.parse(text);
}

/// Standalone top-level function for background CSV isolate execution via compute().
List<ExtractedLectureCandidate> _parseCsvInIsolate(String csvContent) {
  final parser = CsvTimetableParser();
  return parser.parseToCandidates(csvContent);
}
