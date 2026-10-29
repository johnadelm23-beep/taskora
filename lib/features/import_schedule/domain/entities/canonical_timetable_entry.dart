import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';

/// Canonical internal representation of a timetable lecture entry.
///
/// Every timetable imported from CSV, PDF, or image OCR is converted into this
/// canonical schema before validation, review, and persistence.
///
/// Standard schema:
/// - Weekday (0: Sunday ... 6: Saturday)
/// - Course Name (non-empty string)
/// - Start Time (24-hour "HH:mm")
/// - End Time (24-hour "HH:mm")
/// - Instructor (optional string)
/// - Room (optional string)
class CanonicalTimetableEntry {
  final int? weekday; // 0: Sunday ... 6: Saturday
  final String courseName;
  final String? startTime; // "HH:mm" 24-hour
  final String? endTime; // "HH:mm" 24-hour
  final String instructor; // Optional
  final String room; // Optional
  final String courseCode; // Optional

  // Raw original string representations before normalization (for audit/review)
  final String? rawWeekday;
  final String? rawStartTime;
  final String? rawEndTime;

  const CanonicalTimetableEntry({
    this.weekday,
    required this.courseName,
    this.startTime,
    this.endTime,
    this.instructor = '',
    this.room = '',
    this.courseCode = '',
    this.rawWeekday,
    this.rawStartTime,
    this.rawEndTime,
  });

  /// Whether all required fields are present: Weekday, Course Name, Start Time, End Time.
  bool get hasRequiredFields {
    return courseName.trim().isNotEmpty &&
        weekday != null &&
        weekday! >= 0 &&
        weekday! <= 6 &&
        startTime != null &&
        startTime!.isNotEmpty &&
        endTime != null &&
        endTime!.isNotEmpty;
  }

  /// Whether the normalized start and end time range is chronologically valid.
  bool get isTimeRangeValid {
    if (startTime == null || endTime == null) return false;
    return startTime!.compareTo(endTime!) < 0;
  }

  /// Whether end time is strictly earlier than start time.
  bool get isTimeRangeReversed {
    if (startTime == null || endTime == null) return false;
    return startTime!.compareTo(endTime!) > 0;
  }

  /// Whether start and end time are identical.
  bool get isTimeRangeIdentical {
    if (startTime == null || endTime == null) return false;
    return startTime == endTime;
  }

  /// Overall validity check.
  /// Required fields must be present and time range must be strictly ascending.
  /// Note: Missing [instructor] or [room] does NOT invalidate this entry.
  bool get isValid => hasRequiredFields && isTimeRangeValid;

  /// Detailed human-readable validation errors.
  List<String> get validationErrors {
    final errors = <String>[];
    if (courseName.trim().isEmpty) {
      errors.add('Course name is required');
    }
    if (weekday == null || weekday! < 0 || weekday! > 6) {
      errors.add('Weekday is required');
    }
    if (startTime == null || startTime!.isEmpty) {
      errors.add('Start time is required');
    }
    if (endTime == null || endTime!.isEmpty) {
      errors.add('End time is required');
    } else if (startTime != null && startTime!.isNotEmpty) {
      if (isTimeRangeReversed) {
        errors.add(
          'End time ($endTime) is earlier than start time ($startTime)',
        );
      } else if (isTimeRangeIdentical) {
        errors.add('Start time and end time cannot be identical ($startTime)');
      }
    }
    return errors;
  }

  /// Converts this canonical entry into an [ExtractedLectureCandidate] for UI review.
  ExtractedLectureCandidate toCandidate({String? id}) {
    return ExtractedLectureCandidate(
      id: id ?? 'cand_${DateTime.now().microsecondsSinceEpoch}',
      courseName: courseName.trim(),
      courseCode: courseCode.trim(),
      room: room.trim(),
      instructor: instructor.trim(),
      dayOfWeek: weekday,
      startTime: startTime,
      endTime: endTime,
    );
  }

  /// Creates a canonical entry from an [ExtractedLectureCandidate].
  factory CanonicalTimetableEntry.fromCandidate(
    ExtractedLectureCandidate candidate,
  ) {
    return CanonicalTimetableEntry(
      weekday: candidate.dayOfWeek,
      courseName: candidate.courseName,
      startTime: candidate.startTime,
      endTime: candidate.endTime,
      instructor: candidate.instructor,
      room: candidate.room,
      courseCode: candidate.courseCode,
    );
  }

  CanonicalTimetableEntry copyWith({
    int? weekday,
    String? courseName,
    String? startTime,
    String? endTime,
    String? instructor,
    String? room,
    String? courseCode,
    String? rawWeekday,
    String? rawStartTime,
    String? rawEndTime,
    bool clearWeekday = false,
    bool clearStartTime = false,
    bool clearEndTime = false,
  }) {
    return CanonicalTimetableEntry(
      weekday: clearWeekday ? null : (weekday ?? this.weekday),
      courseName: courseName ?? this.courseName,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      instructor: instructor ?? this.instructor,
      room: room ?? this.room,
      courseCode: courseCode ?? this.courseCode,
      rawWeekday: rawWeekday ?? this.rawWeekday,
      rawStartTime: rawStartTime ?? this.rawStartTime,
      rawEndTime: rawEndTime ?? this.rawEndTime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanonicalTimetableEntry &&
          runtimeType == other.runtimeType &&
          weekday == other.weekday &&
          courseName == other.courseName &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          instructor == other.instructor &&
          room == other.room &&
          courseCode == other.courseCode;

  @override
  int get hashCode => Object.hash(
    weekday,
    courseName,
    startTime,
    endTime,
    instructor,
    room,
    courseCode,
  );

  @override
  String toString() {
    return 'CanonicalTimetableEntry(day: $weekday, course: "$courseName", time: $startTime-$endTime, inst: "$instructor", room: "$room")';
  }
}
