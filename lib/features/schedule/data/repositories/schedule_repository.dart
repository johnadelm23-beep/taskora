import 'package:drift/drift.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

abstract class ScheduleRepository {
  Stream<List<LectureEntity>> watchLecturesForDay(int dayOfWeek);
  Stream<List<LectureEntity>> watchAllLectures();
  Future<List<LectureEntity>> getLecturesForDay(int dayOfWeek);
  Future<List<LectureEntity>> getAllLectures();
  Future<LectureEntity?> findConflictingLecture(LectureEntity lecture);
  Future<int> addLecture(LectureEntity lecture);
  Future<bool> updateLecture(LectureEntity lecture);
  Future<int> deleteLecture(int id);
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  final AppDatabase _database;

  ScheduleRepositoryImpl(this._database);

  @override
  Stream<List<LectureEntity>> watchLecturesForDay(int dayOfWeek) {
    final query = _database.select(_database.lectures)
      ..where((tbl) => tbl.dayOfWeek.equals(dayOfWeek))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
      ]);

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<LectureEntity>> watchAllLectures() {
    final query = _database.select(_database.lectures)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.dayOfWeek, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
      ]);

    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<LectureEntity>> getLecturesForDay(int dayOfWeek) async {
    final query = _database.select(_database.lectures)
      ..where((tbl) => tbl.dayOfWeek.equals(dayOfWeek))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
      ]);

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<LectureEntity>> getAllLectures() async {
    final query = _database.select(_database.lectures)
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.dayOfWeek, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.startTime, mode: OrderingMode.asc),
      ]);

    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<LectureEntity?> findConflictingLecture(LectureEntity lecture) async {
    final dayLectures = await getLecturesForDay(lecture.dayOfWeek);
    for (final existing in dayLectures) {
      if (lecture.overlapsWith(existing)) {
        return existing;
      }
    }
    return null;
  }

  @override
  Future<int> addLecture(LectureEntity lecture) {
    final now = DateTime.now();
    return _database
        .into(_database.lectures)
        .insert(
          LecturesCompanion.insert(
            courseName: lecture.courseName,
            courseCode: Value(lecture.courseCode),
            room: Value(lecture.room),
            instructor: Value(lecture.instructor),
            dayOfWeek: lecture.dayOfWeek,
            startTime: lecture.startTime,
            endTime: lecture.endTime,
            colorHex: Value(lecture.colorHex),
            notes: Value(lecture.notes),
            createdAt: Value(lecture.createdAt ?? now),
            updatedAt: Value(now),
          ),
        );
  }

  @override
  Future<bool> updateLecture(LectureEntity lecture) {
    return _database
        .update(_database.lectures)
        .replace(
          Lecture(
            id: lecture.id,
            courseName: lecture.courseName,
            courseCode: lecture.courseCode,
            room: lecture.room,
            instructor: lecture.instructor,
            dayOfWeek: lecture.dayOfWeek,
            startTime: lecture.startTime,
            endTime: lecture.endTime,
            colorHex: lecture.colorHex,
            notes: lecture.notes,
            createdAt: lecture.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<int> deleteLecture(int id) {
    return (_database.delete(
      _database.lectures,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  LectureEntity _toEntity(Lecture row) {
    return LectureEntity(
      id: row.id,
      courseName: row.courseName,
      courseCode: row.courseCode,
      room: row.room,
      instructor: row.instructor,
      dayOfWeek: row.dayOfWeek,
      startTime: row.startTime,
      endTime: row.endTime,
      colorHex: row.colorHex,
      notes: row.notes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
