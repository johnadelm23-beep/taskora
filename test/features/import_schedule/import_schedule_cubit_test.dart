import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_state.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

void main() {
  late AppDatabase database;
  late ScheduleRepository repository;
  late CsvTimetableParser parser;
  late ImportScheduleCubit cubit;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepositoryImpl(database);
    parser = CsvTimetableParser();
    cubit = ImportScheduleCubit(
      csvParser: parser,
      scheduleRepository: repository,
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  group('ImportScheduleCubit - CSV-only Import Pipeline', () {
    test('initial state has status initial and empty candidates', () {
      expect(cubit.state.status, ImportStatus.initial);
      expect(cubit.state.candidates, isEmpty);
      expect(cubit.state.canConfirmImport, isFalse);
    });

    test(
      'processCsvContent parses English CSV rows and emits review status',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,Algorithms,09:00 AM,10:30 AM,Dr. Alan,Lab 1
Tuesday,Operating Systems,11:00 AM,12:30 PM,Dr. Linus,Room 202
''';
        await cubit.processCsvContent(csv, fileName: 'timetable.csv');

        expect(cubit.state.status, ImportStatus.review);
        expect(cubit.state.sourceFileName, 'timetable.csv');
        expect(cubit.state.candidates.length, 2);

        final c1 = cubit.state.candidates[0];
        expect(c1.courseName, 'Algorithms');
        expect(c1.dayOfWeek, 1);
        expect(c1.startTime, '09:00');
        expect(c1.endTime, '10:30');
        expect(c1.instructor, 'Dr. Alan');
        expect(c1.room, 'Lab 1');
        expect(c1.isValid, isTrue);

        final c2 = cubit.state.candidates[1];
        expect(c2.courseName, 'Operating Systems');
        expect(c2.dayOfWeek, 2);
        expect(c2.startTime, '11:00');
        expect(c2.endTime, '12:30');
        expect(c2.isValid, isTrue);

        expect(cubit.state.validCount, 2);
        expect(cubit.state.canConfirmImport, isTrue);
      },
    );

    test(
      'processCsvContent parses Arabic CSV rows with Arabic day names and text',
      () async {
        const csv = '''
اليوم,اسم المقرر,وقت البدء,وقت الانتهاء,المحاضر,القاعة
الأحد,هندسة البرمجيات,09:00 ص,10:30 ص,د. أحمد علي,قاعة 102
الخميس,قواعد البيانات,11:00 ص,12:30 م,د. سارة,معمل 3
''';
        await cubit.processCsvContent(csv, fileName: 'schedule_ar.csv');

        expect(cubit.state.status, ImportStatus.review);
        expect(cubit.state.candidates.length, 2);

        final c1 = cubit.state.candidates[0];
        expect(c1.courseName, 'هندسة البرمجيات');
        expect(c1.dayOfWeek, 0); // Sunday (الأحد)
        expect(c1.startTime, '09:00');
        expect(c1.endTime, '10:30');
        expect(c1.instructor, 'د. أحمد علي');
        expect(c1.room, 'قاعة 102');
        expect(c1.isValid, isTrue);

        final c2 = cubit.state.candidates[1];
        expect(c2.courseName, 'قواعد البيانات');
        expect(c2.dayOfWeek, 4); // Thursday (الخميس)
        expect(c2.startTime, '11:00');
        expect(c2.endTime, '12:30');
        expect(c2.isValid, isTrue);
      },
    );

    test('processCsvContent strips UTF-8 BOM cleanly', () async {
      const csv =
          '\uFEFFWeekday,Course Name,Start Time,End Time,Instructor,Room\n'
          'Monday,Artificial Intelligence,08:30,10:00,Dr. Turing,Hall A\n';

      await cubit.processCsvContent(csv, fileName: 'bom_timetable.csv');

      expect(cubit.state.status, ImportStatus.review);
      expect(cubit.state.candidates.length, 1);
      expect(
        cubit.state.candidates.first.courseName,
        'Artificial Intelligence',
      );
      expect(cubit.state.candidates.first.isValid, isTrue);
    });

    test(
      'processCsvContent handles empty optional fields (Instructor and Room)',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Wednesday,Linear Algebra,10:00,11:30,,
''';
        await cubit.processCsvContent(csv, fileName: 'optional_fields.csv');

        expect(cubit.state.status, ImportStatus.review);
        expect(cubit.state.candidates.length, 1);
        final c = cubit.state.candidates.first;
        expect(c.courseName, 'Linear Algebra');
        expect(c.instructor, isEmpty);
        expect(c.room, isEmpty);
        expect(c.isValid, isTrue);
        expect(cubit.state.canConfirmImport, isTrue);
      },
    );

    test(
      'processCsvContent flags invalid weekdays and invalid times',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
InvalidDay,Robotics,09:00,10:30,Dr. R,Lab 1
Monday,Reversed Lecture,12:00,10:00,Dr. Backwards,Lab 2
''';
        await cubit.processCsvContent(csv, fileName: 'invalid.csv');

        expect(cubit.state.status, ImportStatus.review);
        expect(cubit.state.candidates.length, 2);

        // Invalid Day
        expect(cubit.state.candidates[0].dayOfWeek, isNull);
        expect(cubit.state.candidates[0].isValid, isFalse);

        // Reversed Time (End before Start)
        expect(cubit.state.candidates[1].isValid, isFalse);
        expect(
          cubit.state.candidates[1].validationErrors.any(
            (e) => e.contains('earlier than start time'),
          ),
          isTrue,
        );

        expect(cubit.state.canConfirmImport, isFalse);
      },
    );

    test(
      'processCsvFile rejects non-csv file extension with clear error',
      () async {
        await cubit.processCsvFile('documents/schedule.pdf');

        expect(cubit.state.status, ImportStatus.failure);
        expect(
          cubit.state.errorMessage,
          contains('Only .csv files are supported'),
        );
      },
    );

    test(
      'processCsvFile rejects non-existent .csv file with clear error',
      () async {
        await cubit.processCsvFile('non_existent_folder/missing.csv');

        expect(cubit.state.status, ImportStatus.failure);
        expect(cubit.state.errorMessage, contains('File not found'));
      },
    );

    test('detects conflict against existing lecture in repository', () async {
      // 1. Add existing lecture to database (Monday 10:00 - 11:30)
      await repository.addLecture(
        const LectureEntity(
          id: 0,
          courseName: 'Algorithms',
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '11:30',
        ),
      );

      // 2. Import CSV with overlapping Monday class (10:30 - 12:00)
      const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,Computer Networks,10:30,12:00,Dr. Gates,Hall B
''';
      await cubit.processCsvContent(csv);

      expect(cubit.state.candidates.length, 1);
      final c = cubit.state.candidates.first;
      expect(c.hasConflict, isTrue);
      expect(
        c.conflictReason,
        contains('Overlaps with existing class: Algorithms'),
      );
    });

    test(
      'updateCandidate modifies candidate and re-evaluates validation',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
,Missing Day Course,10:00,11:30,Dr. A,Room 1
''';
        await cubit.processCsvContent(csv);
        expect(cubit.state.candidates.first.dayOfWeek, isNull);
        expect(cubit.state.canConfirmImport, isFalse);

        // User fixes candidate by setting Monday (dayOfWeek = 1)
        final candidate = cubit.state.candidates.first;
        cubit.updateCandidate(0, candidate.copyWith(dayOfWeek: 1));

        expect(cubit.state.candidates.first.dayOfWeek, 1);
        expect(cubit.state.candidates.first.isValid, isTrue);
        expect(cubit.state.canConfirmImport, isTrue);
      },
    );

    test(
      'addManualCandidate appends a new lecture candidate for user review',
      () {
        expect(cubit.state.candidates, isEmpty);
        cubit.addManualCandidate();
        expect(cubit.state.candidates.length, 1);
      },
    );

    test('removeCandidate removes item from candidate list', () async {
      const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,CS101 Intro,10:00,11:30,Dr. A,Room 1
Tuesday,MATH201 Calculus,09:00,10:30,Dr. B,Room 2
''';
      await cubit.processCsvContent(csv);
      expect(cubit.state.candidates.length, 2);

      cubit.removeCandidate(0);
      expect(cubit.state.candidates.length, 1);
      expect(cubit.state.candidates.first.courseName, 'MATH201 Calculus');
    });

    test(
      'confirmImport saves valid candidates to database and skips duplicates if configured',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,CS101 Intro,10:00,11:30,Dr. A,Room 1
Tuesday,MATH201 Calculus,09:00,10:30,Dr. B,Room 2
''';
        await cubit.processCsvContent(csv);
        expect(cubit.state.canConfirmImport, isTrue);

        await cubit.confirmImport(skipDuplicates: true);

        expect(cubit.state.status, ImportStatus.success);
        expect(cubit.state.result?.importedCount, 2);
        expect(cubit.state.result?.skippedDuplicatesCount, 0);

        // Verify records exist in DB
        final dbLectures = await repository.getAllLectures();
        expect(dbLectures.length, 2);

        // Re-importing same CSV skips duplicates
        await cubit.processCsvContent(csv);
        await cubit.confirmImport(skipDuplicates: true);

        expect(cubit.state.status, ImportStatus.success);
        expect(cubit.state.result?.importedCount, 0);
        expect(cubit.state.result?.skippedDuplicatesCount, 2);
        final finalDbCount = await repository.getAllLectures();
        expect(finalDbCount.length, 2); // preserved
      },
    );
  });
}
