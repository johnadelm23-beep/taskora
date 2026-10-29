import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';

void main() {
  late AppDatabase db;
  late ScheduleRepository repository;
  late ScheduleCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepositoryImpl(db);
    cubit = ScheduleCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  group('ScheduleCubit', () {
    const lectureMonday = LectureEntity(
      id: 0,
      courseName: 'Mobile Dev',
      courseCode: 'CS302',
      room: 'Lab 1',
      instructor: 'Dr. Sarah',
      dayOfWeek: 1,
      startTime: '10:00',
      endTime: '11:30',
    );

    test('addLecture adds lecture and streams updates to state', () async {
      cubit.selectDay(1);

      final success = await cubit.addLecture(lectureMonday);
      expect(success, isTrue);

      // Wait a moment for stream to emit
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.dayLectures.length, equals(1));
      expect(cubit.state.dayLectures.first.courseName, equals('Mobile Dev'));
      expect(cubit.state.errorMessage, isNull);
    });

    test(
      'addLecture fails with descriptive error message on overlap',
      () async {
        cubit.selectDay(1);
        await cubit.addLecture(lectureMonday);

        const overlapping = LectureEntity(
          id: 0,
          courseName: 'Web Security',
          dayOfWeek: 1,
          startTime: '10:30',
          endTime: '12:00',
        );

        final success = await cubit.addLecture(overlapping);
        expect(success, isFalse);
        expect(
          cubit.state.errorMessage,
          contains('Time conflict with "Mobile Dev"'),
        );
      },
    );

    test(
      'updateLecture updates existing lecture and re-verifies conflicts',
      () async {
        cubit.selectDay(1);
        await cubit.addLecture(lectureMonday);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final added = cubit.state.dayLectures.first;
        final updated = added.copyWith(courseName: 'Advanced Mobile Dev');

        final success = await cubit.updateLecture(updated);
        expect(success, isTrue);

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          cubit.state.dayLectures.first.courseName,
          equals('Advanced Mobile Dev'),
        );
      },
    );

    test('deleteLecture removes the lecture from the day list', () async {
      cubit.selectDay(1);
      await cubit.addLecture(lectureMonday);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final added = cubit.state.dayLectures.first;
      await cubit.deleteLecture(added.id);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.dayLectures, isEmpty);
    });

    test(
      'selectDay changes selectedDayIndex and loads correct day lectures',
      () async {
        cubit.selectDay(1);
        await cubit.addLecture(lectureMonday);

        // Switch to Day 3 (Wednesday)
        cubit.selectDay(3);
        expect(cubit.state.selectedDayIndex, equals(3));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cubit.state.dayLectures, isEmpty);

        // Switch back to Day 1 (Monday)
        cubit.selectDay(1);
        expect(cubit.state.selectedDayIndex, equals(1));

        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(cubit.state.dayLectures.length, equals(1));
      },
    );
  });
}
