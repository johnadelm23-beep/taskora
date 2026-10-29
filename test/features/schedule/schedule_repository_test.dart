import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ScheduleRepositoryImpl', () {
    const lecture1 = LectureEntity(
      id: 0,
      courseName: 'Algorithms',
      courseCode: 'CS201',
      room: 'Hall A',
      instructor: 'Dr. Alice',
      dayOfWeek: 1, // Monday
      startTime: '09:00',
      endTime: '10:30',
      notes: 'Bring laptop',
    );

    const lecture2 = LectureEntity(
      id: 0,
      courseName: 'Operating Systems',
      courseCode: 'CS202',
      room: 'Hall B',
      instructor: 'Dr. Bob',
      dayOfWeek: 1, // Monday
      startTime: '11:00',
      endTime: '12:30',
    );

    test(
      'addLecture persists and getLecturesForDay retrieves sorted lectures',
      () async {
        await repository.addLecture(lecture2);
        await repository.addLecture(lecture1);

        final mondayLectures = await repository.getLecturesForDay(1);
        expect(mondayLectures.length, equals(2));
        // Verify chronological ordering by startTime
        expect(mondayLectures[0].courseName, equals('Algorithms'));
        expect(mondayLectures[0].startTime, equals('09:00'));
        expect(mondayLectures[1].courseName, equals('Operating Systems'));
        expect(mondayLectures[1].startTime, equals('11:00'));
      },
    );

    test(
      'findConflictingLecture detects time overlaps on the same day',
      () async {
        final id1 = await repository.addLecture(lecture1);

        // Overlapping lecture (09:30 - 11:00 overlaps with 09:00 - 10:30)
        const conflictLecture = LectureEntity(
          id: 0,
          courseName: 'Data Structures',
          dayOfWeek: 1,
          startTime: '09:30',
          endTime: '11:00',
        );

        final conflict = await repository.findConflictingLecture(
          conflictLecture,
        );
        expect(conflict, isNotNull);
        expect(conflict!.id, equals(id1));
        expect(conflict.courseName, equals('Algorithms'));

        // Non-overlapping lecture on same day (10:30 - 12:00)
        const nonConflictLecture = LectureEntity(
          id: 0,
          courseName: 'Linear Algebra',
          dayOfWeek: 1,
          startTime: '10:30',
          endTime: '12:00',
        );

        final noConflict = await repository.findConflictingLecture(
          nonConflictLecture,
        );
        expect(noConflict, isNull);

        // Same time on different day (Tuesday)
        const differentDayLecture = LectureEntity(
          id: 0,
          courseName: 'Physics',
          dayOfWeek: 2,
          startTime: '09:00',
          endTime: '10:30',
        );

        final diffDayConflict = await repository.findConflictingLecture(
          differentDayLecture,
        );
        expect(diffDayConflict, isNull);
      },
    );

    test('updateLecture modifies lecture details in database', () async {
      final id = await repository.addLecture(lecture1);
      final added = (await repository.getLecturesForDay(1)).first;

      final updated = added.copyWith(
        courseName: 'Advanced Algorithms',
        room: 'Lab 3',
        endTime: '10:45',
      );

      final success = await repository.updateLecture(updated);
      expect(success, isTrue);

      final retrieved = (await repository.getLecturesForDay(1)).first;
      expect(retrieved.id, equals(id));
      expect(retrieved.courseName, equals('Advanced Algorithms'));
      expect(retrieved.room, equals('Lab 3'));
      expect(retrieved.endTime, equals('10:45'));
    });

    test('deleteLecture removes the lecture from database', () async {
      final id = await repository.addLecture(lecture1);
      var lectures = await repository.getLecturesForDay(1);
      expect(lectures.length, equals(1));

      final deletedRows = await repository.deleteLecture(id);
      expect(deletedRows, equals(1));

      lectures = await repository.getLecturesForDay(1);
      expect(lectures, isEmpty);
    });

    test(
      'getAllLectures returns all lectures ordered by day and startTime',
      () async {
        await repository.addLecture(lecture2); // Day 1, 11:00
        await repository.addLecture(
          const LectureEntity(
            id: 0,
            courseName: 'Sunday Class',
            dayOfWeek: 0,
            startTime: '08:00',
            endTime: '09:30',
          ),
        );
        await repository.addLecture(lecture1); // Day 1, 09:00

        final all = await repository.getAllLectures();
        expect(all.length, equals(3));
        expect(all[0].courseName, equals('Sunday Class'));
        expect(all[1].courseName, equals('Algorithms'));
        expect(all[2].courseName, equals('Operating Systems'));
      },
    );
  });
}
