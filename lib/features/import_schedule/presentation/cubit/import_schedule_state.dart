import 'package:flutter/foundation.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/entities/import_result.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

enum ImportStatus {
  initial,
  picking,
  processing,
  review,
  saving,
  success,
  failure,
}

class ImportScheduleState {
  final ImportStatus status;
  final String? processingMessage;
  final String? sourceFileName;
  final String? sourceFilePath;
  final bool isImage;
  final String? rawExtractedText;
  final List<ExtractedLectureCandidate> candidates;
  final List<LectureEntity> existingLectures;
  final ImportResult? result;
  final String? errorMessage;

  const ImportScheduleState({
    this.status = ImportStatus.initial,
    this.processingMessage,
    this.sourceFileName,
    this.sourceFilePath,
    this.isImage = false,
    this.rawExtractedText,
    this.candidates = const [],
    this.existingLectures = const [],
    this.result,
    this.errorMessage,
  });

  int get totalCount => candidates.length;
  int get validCount => candidates.where((c) => c.isValid).length;
  int get invalidCount => candidates.where((c) => !c.isValid).length;
  int get conflictCount => candidates.where((c) => c.hasConflict).length;
  int get duplicateCount => candidates.where((c) => c.isDuplicate).length;

  bool get canConfirmImport =>
      candidates.isNotEmpty && candidates.every((c) => c.isValid);

  ImportScheduleState copyWith({
    ImportStatus? status,
    String? processingMessage,
    String? sourceFileName,
    String? sourceFilePath,
    bool? isImage,
    String? rawExtractedText,
    List<ExtractedLectureCandidate>? candidates,
    List<LectureEntity>? existingLectures,
    ImportResult? result,
    String? errorMessage,
    bool clearProcessingMessage = false,
    bool clearError = false,
  }) {
    return ImportScheduleState(
      status: status ?? this.status,
      processingMessage: clearProcessingMessage
          ? null
          : (processingMessage ?? this.processingMessage),
      sourceFileName: sourceFileName ?? this.sourceFileName,
      sourceFilePath: sourceFilePath ?? this.sourceFilePath,
      isImage: isImage ?? this.isImage,
      rawExtractedText: rawExtractedText ?? this.rawExtractedText,
      candidates: candidates ?? this.candidates,
      existingLectures: existingLectures ?? this.existingLectures,
      result: result ?? this.result,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImportScheduleState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          processingMessage == other.processingMessage &&
          sourceFileName == other.sourceFileName &&
          sourceFilePath == other.sourceFilePath &&
          isImage == other.isImage &&
          rawExtractedText == other.rawExtractedText &&
          errorMessage == other.errorMessage &&
          listEquals(candidates, other.candidates) &&
          listEquals(existingLectures, other.existingLectures);

  @override
  int get hashCode => Object.hash(
    status,
    processingMessage,
    sourceFileName,
    sourceFilePath,
    isImage,
    rawExtractedText,
    errorMessage,
    candidates.length,
    existingLectures.length,
  );
}
