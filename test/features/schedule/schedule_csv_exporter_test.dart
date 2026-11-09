import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/domain/services/schedule_csv_exporter.dart';

void main() {
  late AppDatabase database;
  late ScheduleRepository repository;
  late CsvTimetableParser parser;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepositoryImpl(database);
    parser = CsvTimetableParser();
  });

  tearDown(() async {
    await database.close();
  });

  group('ScheduleCsvExporter - Database Records Export & Round-Trip', () {
    test('exports empty lecture list with BOM and headers', () {
      final csv = ScheduleCsvExporter.generateCsv([], isArabic: false);

      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(
        csv,
        equals(
          '\uFEFFWeekday,Course Name,Course Code,Start Time,End Time,Instructor,Room,Notes\r\n',
        ),
      );
    });

    test(
      'exports actual Drift database records and matches exactly when parsed back',
      () async {
        // 1. Add records into the real Drift database
        await repository.addLecture(
          const LectureEntity(
            id: 0,
            courseName: 'Algorithms & Data Structures',
            courseCode: 'CS201',
            dayOfWeek: 0, // Sunday
            startTime: '09:00',
            endTime: '10:30',
            instructor: 'Dr. Alan Turing',
            room: 'Hall 101',
            notes: 'Bring reference textbook',
          ),
        );

        await repository.addLecture(
          const LectureEntity(
            id: 0,
            courseName: 'Operating Systems',
            courseCode: 'CS302',
            dayOfWeek: 1, // Monday
            startTime: '11:00',
            endTime: '12:30',
            instructor: 'Dr. Linus Torvalds',
            room: 'Lab 3',
            notes: 'Kernel assignment due',
          ),
        );

        await repository.addLecture(
          const LectureEntity(
            id: 0,
            courseName: 'Database Systems',
            courseCode: 'CS204',
            dayOfWeek: 2, // Tuesday
            startTime: '14:00',
            endTime: '15:30',
            instructor: 'Dr. Edgar Codd',
            room: 'Room 205',
          ),
        );

        // 2. Fetch actual saved database records
        final dbLectures = await repository.getAllLectures();
        expect(dbLectures.length, 3);

        // 3. Export to CSV string
        final exportedCsv = ScheduleCsvExporter.generateCsv(
          dbLectures,
          isArabic: false,
        );

        // Verify UTF-8 BOM presence
        expect(exportedCsv.startsWith('\uFEFF'), isTrue);

        // Verify headers
        expect(
          exportedCsv,
          contains(
            'Weekday,Course Name,Course Code,Start Time,End Time,Instructor,Room,Notes',
          ),
        );

        // 4. Parse the exported CSV using CsvTimetableParser
        final parsedCanonical = parser.parseToCanonical(exportedCsv);
        expect(parsedCanonical.length, 3);

        // Verify Record 1 (Sunday - Algorithms)
        final p1 = parsedCanonical[0];
        expect(p1.weekday, 0);
        expect(p1.courseName, 'Algorithms & Data Structures');
        expect(p1.courseCode, 'CS201');
        expect(p1.startTime, '09:00');
        expect(p1.endTime, '10:30');
        expect(p1.instructor, 'Dr. Alan Turing');
        expect(p1.room, 'Hall 101');
        expect(p1.notes, 'Bring reference textbook');
        expect(p1.isValid, isTrue);

        // Verify Record 2 (Monday - Operating Systems)
        final p2 = parsedCanonical[1];
        expect(p2.weekday, 1);
        expect(p2.courseName, 'Operating Systems');
        expect(p2.courseCode, 'CS302');
        expect(p2.startTime, '11:00');
        expect(p2.endTime, '12:30');
        expect(p2.instructor, 'Dr. Linus Torvalds');
        expect(p2.room, 'Lab 3');
        expect(p2.notes, 'Kernel assignment due');
        expect(p2.isValid, isTrue);

        // Verify Record 3 (Tuesday - Database Systems)
        final p3 = parsedCanonical[2];
        expect(p3.weekday, 2);
        expect(p3.courseName, 'Database Systems');
        expect(p3.courseCode, 'CS204');
        expect(p3.startTime, '14:00');
        expect(p3.endTime, '15:30');
        expect(p3.instructor, 'Dr. Edgar Codd');
        expect(p3.room, 'Room 205');
        expect(p3.notes, isEmpty);
        expect(p3.isValid, isTrue);
      },
    );

    test('exports Arabic records with Arabic headers and day names', () async {
      await repository.addLecture(
        const LectureEntity(
          id: 0,
          courseName: 'هندسة البرمجيات',
          courseCode: 'SE401',
          dayOfWeek: 0, // الأحد
          startTime: '08:30',
          endTime: '10:00',
          instructor: 'د. أحمد علي',
          room: 'مدرج 2',
          notes: 'مشروع التخرج',
        ),
      );

      await repository.addLecture(
        const LectureEntity(
          id: 0,
          courseName: 'الذكاء الاصطناعي',
          courseCode: 'AI302',
          dayOfWeek: 4, // الخميس
          startTime: '10:30',
          endTime: '12:00',
          instructor: 'د. منى سعيد',
          room: 'معمل 4',
        ),
      );

      final dbLectures = await repository.getAllLectures();
      expect(dbLectures.length, 2);

      // Export with Arabic headers
      final arabicCsv = ScheduleCsvExporter.generateCsv(
        dbLectures,
        isArabic: true,
      );

      expect(arabicCsv.startsWith('\uFEFF'), isTrue);
      expect(
        arabicCsv,
        contains(
          'اليوم,اسم المقرر,كود المقرر,وقت البدء,وقت الانتهاء,المحاضر,القاعة,ملاحظات',
        ),
      );
      expect(arabicCsv, contains('الأحد'));
      expect(arabicCsv, contains('الخميس'));

      // Parse back through CsvTimetableParser
      final parsed = parser.parseToCanonical(arabicCsv);
      expect(parsed.length, 2);

      expect(parsed[0].weekday, 0);
      expect(parsed[0].courseName, 'هندسة البرمجيات');
      expect(parsed[0].courseCode, 'SE401');
      expect(parsed[0].startTime, '08:30');
      expect(parsed[0].endTime, '10:00');
      expect(parsed[0].instructor, 'د. أحمد علي');
      expect(parsed[0].room, 'مدرج 2');
      expect(parsed[0].notes, 'مشروع التخرج');

      expect(parsed[1].weekday, 4);
      expect(parsed[1].courseName, 'الذكاء الاصطناعي');
      expect(parsed[1].courseCode, 'AI302');
      expect(parsed[1].startTime, '10:30');
      expect(parsed[1].endTime, '12:00');
      expect(parsed[1].instructor, 'د. منى سعيد');
      expect(parsed[1].room, 'معمل 4');
    });

    test(
      'escapes special characters (commas, quotes, newlines) properly',
      () async {
        await repository.addLecture(
          const LectureEntity(
            id: 0,
            courseName: 'Math, Science & Logic',
            courseCode: 'GEN101',
            dayOfWeek: 3, // Wednesday
            startTime: '13:00',
            endTime: '14:30',
            instructor: 'Dr. "Special" One',
            room: 'Room 1, Floor 2',
            notes: 'Notes with\nnewline and "quotes"',
          ),
        );

        final dbLectures = await repository.getAllLectures();
        final csv = ScheduleCsvExporter.generateCsv(dbLectures);

        expect(csv, contains('"Math, Science & Logic"'));
        expect(csv, contains('"Dr. ""Special"" One"'));
        expect(csv, contains('"Room 1, Floor 2"'));

        final parsed = parser.parseToCanonical(csv);
        expect(parsed.length, 1);
        expect(parsed.first.courseName, 'Math, Science & Logic');
        expect(parsed.first.instructor, 'Dr. "Special" One');
        expect(parsed.first.room, 'Room 1, Floor 2');
      },
    );
  });
}
