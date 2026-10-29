class LectureEntity {
  final int id;
  final String courseName;
  final String courseCode;
  final String room;
  final String instructor;
  final int dayOfWeek; // 0: Sunday ... 6: Saturday
  final String startTime; // "HH:mm" (24-hour)
  final String endTime; // "HH:mm" (24-hour)
  final int? colorHex;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const LectureEntity({
    required this.id,
    required this.courseName,
    this.courseCode = '',
    this.room = '',
    this.instructor = '',
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.colorHex,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  bool overlapsWith(LectureEntity other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    if (id != 0 && other.id != 0 && id == other.id) return false;
    return startTime.compareTo(other.endTime) < 0 &&
        endTime.compareTo(other.startTime) > 0;
  }

  LectureEntity copyWith({
    int? id,
    String? courseName,
    String? courseCode,
    String? room,
    String? instructor,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? colorHex,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LectureEntity(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      room: room ?? this.room,
      instructor: instructor ?? this.instructor,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      colorHex: colorHex ?? this.colorHex,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
