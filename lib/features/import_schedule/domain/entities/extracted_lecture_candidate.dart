import 'package:taskora/features/import_schedule/domain/entities/canonical_timetable_entry.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class ExtractedLectureCandidate {
  final String id;
  final String courseName;
  final String courseCode;
  final String room;
  final String instructor;
  final int? dayOfWeek; // 0: Sunday ... 6: Saturday
  final String? startTime; // "HH:mm" 24-hour
  final String? endTime; // "HH:mm" 24-hour
  final int? colorHex;
  final String? notes;
  final double confidence; // 0.0 to 1.0
  final bool isDuplicate;
  final bool hasConflict;
  final String? conflictReason;

  const ExtractedLectureCandidate({
    required this.id,
    required this.courseName,
    this.courseCode = '',
    this.room = '',
    this.instructor = '',
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.colorHex,
    this.notes,
    this.confidence = 1.0,
    this.isDuplicate = false,
    this.hasConflict = false,
    this.conflictReason,
  });

  /// Creates candidate directly from a [CanonicalTimetableEntry].
  factory ExtractedLectureCandidate.fromCanonical(
    CanonicalTimetableEntry entry, {
    String? id,
    int? colorHex,
    String? notes,
  }) {
    return ExtractedLectureCandidate(
      id: id ?? 'cand_${DateTime.now().microsecondsSinceEpoch}',
      courseName: entry.courseName,
      courseCode: entry.courseCode,
      room: entry.room,
      instructor: entry.instructor,
      dayOfWeek: entry.weekday,
      startTime: entry.startTime,
      endTime: entry.endTime,
      colorHex: colorHex,
      notes: notes,
    );
  }

  /// Converts this candidate to a [CanonicalTimetableEntry].
  CanonicalTimetableEntry toCanonical() {
    return CanonicalTimetableEntry(
      weekday: dayOfWeek,
      courseName: courseName,
      startTime: startTime,
      endTime: endTime,
      instructor: instructor,
      room: room,
      courseCode: courseCode,
    );
  }

  bool get isTimeRangeValid {
    if (startTime == null || endTime == null) return false;
    return startTime!.compareTo(endTime!) < 0;
  }

  bool get isTimeRangeReversed {
    if (startTime == null || endTime == null) return false;
    return startTime!.compareTo(endTime!) > 0;
  }

  bool get isValid {
    return courseName.trim().isNotEmpty &&
        dayOfWeek != null &&
        dayOfWeek! >= 0 &&
        dayOfWeek! <= 6 &&
        startTime != null &&
        endTime != null &&
        isTimeRangeValid;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    if (courseName.trim().isEmpty) {
      errors.add('Course name is required');
    }
    if (dayOfWeek == null || dayOfWeek! < 0 || dayOfWeek! > 6) {
      errors.add('Weekday is required');
    }
    if (startTime == null && endTime == null) {
      errors.add('Start and end times are required');
    } else if (startTime == null) {
      errors.add('Start time is required');
    } else if (endTime == null) {
      errors.add('End time is required');
    } else if (isTimeRangeReversed) {
      errors.add('End time ($endTime) is earlier than start time ($startTime)');
    } else if (startTime == endTime) {
      errors.add('Start time and end time cannot be identical');
    }
    return errors;
  }

  String? get validationErrorMessage {
    final errors = validationErrors;
    if (errors.isEmpty) return null;
    return errors.join('. ');
  }

  bool overlapsWith(ExtractedLectureCandidate other) {
    if (id == other.id) return false;
    if (dayOfWeek == null || other.dayOfWeek == null) return false;
    if (dayOfWeek != other.dayOfWeek) return false;
    if (startTime == null ||
        endTime == null ||
        other.startTime == null ||
        other.endTime == null) {
      return false;
    }
    return startTime!.compareTo(other.endTime!) < 0 &&
        endTime!.compareTo(other.startTime!) > 0;
  }

  bool overlapsWithLecture(LectureEntity other) {
    if (dayOfWeek == null || dayOfWeek != other.dayOfWeek) return false;
    if (startTime == null || endTime == null) return false;
    return startTime!.compareTo(other.endTime) < 0 &&
        endTime!.compareTo(other.startTime) > 0;
  }

  bool isDuplicateOf(LectureEntity other) {
    if (dayOfWeek == null || dayOfWeek != other.dayOfWeek) return false;
    if (startTime == null || startTime != other.startTime) return false;
    final normalizedThisName = courseName.trim().toLowerCase();
    final normalizedOtherName = other.courseName.trim().toLowerCase();
    if (normalizedThisName == normalizedOtherName) return true;
    if (endTime != null && endTime == other.endTime) return true;
    return false;
  }

  LectureEntity toLectureEntity({int id = 0}) {
    return LectureEntity(
      id: id,
      courseName: courseName.trim(),
      courseCode: courseCode.trim(),
      room: room.trim(),
      instructor: instructor.trim(),
      dayOfWeek: dayOfWeek ?? 0,
      startTime: startTime ?? '09:00',
      endTime: endTime ?? '10:30',
      colorHex: colorHex,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ExtractedLectureCandidate copyWith({
    String? id,
    String? courseName,
    String? courseCode,
    String? room,
    String? instructor,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? colorHex,
    String? notes,
    double? confidence,
    bool? isDuplicate,
    bool? hasConflict,
    String? conflictReason,
    bool clearDayOfWeek = false,
    bool clearStartTime = false,
    bool clearEndTime = false,
    bool clearConflict = false,
  }) {
    return ExtractedLectureCandidate(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      dayOfWeek: clearDayOfWeek ? null : (dayOfWeek ?? this.dayOfWeek),
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      confidence: confidence ?? this.confidence,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      hasConflict: clearConflict ? false : (hasConflict ?? this.hasConflict),
      conflictReason: clearConflict
          ? null
          : (conflictReason ?? this.conflictReason),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedLectureCandidate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          courseName == other.courseName &&
          courseCode == other.courseCode &&
          room == other.room &&
          instructor == other.instructor &&
          dayOfWeek == other.dayOfWeek &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          isDuplicate == other.isDuplicate &&
          hasConflict == other.hasConflict;

  @override
  int get hashCode => Object.hash(
    id,
    courseName,
    courseCode,
    room,
    instructor,
    dayOfWeek,
    startTime,
    endTime,
    isDuplicate,
    hasConflict,
  );
}
