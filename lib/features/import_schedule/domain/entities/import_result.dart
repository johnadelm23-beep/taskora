import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class ImportResult {
  final int importedCount;
  final int skippedDuplicatesCount;
  final int failedCount;
  final List<LectureEntity> importedLectures;
  final bool isSuccess;
  final String? message;

  const ImportResult({
    required this.importedCount,
    this.skippedDuplicatesCount = 0,
    this.failedCount = 0,
    this.importedLectures = const [],
    required this.isSuccess,
    this.message,
  });

  int get totalProcessed =>
      importedCount + skippedDuplicatesCount + failedCount;
}
