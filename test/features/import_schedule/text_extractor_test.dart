import 'dart:io';
import 'dart:ui';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/import_schedule/data/services/on_device_text_extractor_impl.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';

void main() {
  late Directory tempDir;
  late OnDeviceTextExtractorImpl extractor;
  late TimetableParser parser;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('taskora_pdf_test_');
    extractor = OnDeviceTextExtractorImpl();
    parser = TimetableParser();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test(
    'generates a text-based PDF, extracts text, parses candidates, and saves to database',
    () async {
      // 1. Generate a valid university timetable PDF
      final document = PdfDocument();
      final page = document.pages.add();
      final font = PdfStandardFont(PdfFontFamily.helvetica, 14);

      const scheduleContent = '''
Monday
CS302 Mobile Development
Dr. John Smith
Hall 4
10:00 - 11:30

Wednesday
CS401 Cloud Computing
Prof. Ada Lovelace
Lab 2
13:00 - 14:30
''';

      page.graphics.drawString(
        scheduleContent,
        font,
        bounds: const Rect.fromLTWH(20, 20, 400, 300),
      );

      final pdfBytes = await document.save();
      document.dispose();

      final pdfFile = File('${tempDir.path}/university_timetable.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      // 2. Extract text using the real OnDeviceTextExtractorImpl
      final extractedText = await extractor.extractTextFromPdf(pdfFile.path);
      expect(extractedText, isNotEmpty);
      expect(extractedText, contains('CS302'));
      expect(extractedText, contains('Mobile Development'));

      // 3. Parse candidates using TimetableParser
      final candidates = parser.parse(extractedText);
      expect(candidates.length, 2);

      final first = candidates[0];
      expect(first.courseCode, 'CS302');
      expect(first.dayOfWeek, 1); // Monday
      expect(first.startTime, '10:00');
      expect(first.endTime, '11:30');
      expect(first.room, 'Hall 4');
      expect(first.instructor, 'Dr. John Smith');
      expect(first.isValid, isTrue);

      final second = candidates[1];
      expect(second.courseCode, 'CS401');
      expect(second.dayOfWeek, 3); // Wednesday
      expect(second.startTime, '13:00');
      expect(second.endTime, '14:30');
      expect(second.isValid, isTrue);

      // 4. Persistence test with Drift database across restarts
      final dbFile = File('${tempDir.path}/taskora_test.sqlite');
      if (dbFile.existsSync()) dbFile.deleteSync();

      // Start DB session 1
      var db = AppDatabase(NativeDatabase(dbFile));
      var repository = ScheduleRepositoryImpl(db);
      var cubit = ImportScheduleCubit(
        scheduleRepository: repository,
        parser: parser,
        textExtractor: extractor,
      );

      // Load and modify candidate
      cubit.addCandidate(first);
      // Correct the first candidate's room and notes
      cubit.updateCandidateById(
        first.id,
        first.copyWith(
          room: 'Hall 4B (Corrected)',
          notes: 'Reviewed and corrected during import',
        ),
      );
      cubit.addCandidate(second);

      // Save imported candidates to database
      await cubit.confirmImport();
      final result = cubit.state.result;
      expect(result, isNotNull);
      expect(result!.isSuccess, isTrue);
      expect(result.importedCount, 2);

      await cubit.close();
      await db.close();

      // Start DB session 2 (simulating app restart)
      db = AppDatabase(NativeDatabase(dbFile));
      repository = ScheduleRepositoryImpl(db);

      final savedMonday = await repository.getLecturesForDay(1);
      expect(savedMonday.length, 1);
      expect(savedMonday.first.courseName, contains('Mobile Development'));
      expect(savedMonday.first.room, 'Hall 4B (Corrected)');
      expect(savedMonday.first.notes, 'Reviewed and corrected during import');

      final savedWednesday = await repository.getLecturesForDay(3);
      expect(savedWednesday.length, 1);
      expect(savedWednesday.first.courseName, contains('Cloud Computing'));
      expect(savedWednesday.first.startTime, '13:00');

      await db.close();
    },
  );

  test(
    'extracts and parses seven lecture rows from taskora_sample_timetable.pdf fixture',
    () async {
      final samplePdf = File('test/fixtures/taskora_sample_timetable.pdf');
      expect(samplePdf.existsSync(), isTrue);

      final extractedText = await extractor.extractTextFromPdf(samplePdf.path);
      expect(extractedText, isNotEmpty);

      final candidates = parser.parse(extractedText);
      expect(candidates.length, 7);

      expect(candidates[0].courseName, 'Data Structures');
      expect(candidates[0].dayOfWeek, 0); // Sunday
      expect(candidates[0].startTime, '09:00');
      expect(candidates[0].endTime, '10:30');
      expect(candidates[0].instructor, 'Dr. Ahmed Hassan');
      expect(candidates[0].room, 'Lab 2');
      expect(candidates[0].isValid, isTrue);

      expect(candidates[1].courseName, 'Database Systems');
      expect(candidates[1].dayOfWeek, 0); // Sunday
      expect(candidates[1].startTime, '11:00');
      expect(candidates[1].endTime, '12:30');
      expect(candidates[1].instructor, 'Dr. Mona Ali');
      expect(candidates[1].room, 'Room 105');
      expect(candidates[1].isValid, isTrue);

      expect(candidates[2].courseName, 'Object-Oriented Programming');
      expect(candidates[2].dayOfWeek, 1); // Monday
      expect(candidates[2].startTime, '10:00');
      expect(candidates[2].endTime, '11:30');
      expect(candidates[2].instructor, 'Dr. Karim Nabil');
      expect(candidates[2].room, 'Lab 1');
      expect(candidates[2].isValid, isTrue);

      expect(candidates[3].courseName, 'Operating Systems');
      expect(candidates[3].dayOfWeek, 2); // Tuesday
      expect(candidates[3].startTime, '09:30');
      expect(candidates[3].endTime, '11:00');
      expect(candidates[3].instructor, 'Dr. Salma Youssef');
      expect(candidates[3].room, 'Room 201');
      expect(candidates[3].isValid, isTrue);

      expect(candidates[4].courseName, 'Computer Networks');
      expect(candidates[4].dayOfWeek, 2); // Tuesday
      expect(candidates[4].startTime, '12:00');
      expect(candidates[4].endTime, '13:30');
      expect(candidates[4].instructor, 'Dr. Omar Adel');
      expect(candidates[4].room, 'Room 204');
      expect(candidates[4].isValid, isTrue);

      expect(candidates[5].courseName, 'Database Systems');
      expect(candidates[5].dayOfWeek, 3); // Wednesday
      expect(candidates[5].startTime, '10:00');
      expect(candidates[5].endTime, '11:30');
      expect(candidates[5].instructor, 'Dr. Mona Ali');
      expect(candidates[5].room, 'Room 105');
      expect(candidates[5].isValid, isTrue);

      expect(candidates[6].courseName, 'Software Engineering');
      expect(candidates[6].dayOfWeek, 4); // Thursday
      expect(candidates[6].startTime, '09:00');
      expect(candidates[6].endTime, '10:30');
      expect(candidates[6].instructor, 'Dr. Nour Samir');
      expect(candidates[6].room, 'Room 301');
      expect(candidates[6].isValid, isTrue);
    },
  );

  test(
    'extracts and parses real 5-page Arabic timetable (علوم الحاسب.pdf) into valid candidates across all weekdays',
    () async {
      final arabicPdf = File('test/fixtures/arabic_sample_timetable.pdf');
      expect(arabicPdf.existsSync(), isTrue);

      final extractedText = await extractor.extractTextFromPdf(arabicPdf.path);
      expect(extractedText, isNotEmpty);

      final candidates = parser.parse(extractedText);
      expect(candidates, isNotEmpty);
      expect(candidates.length, greaterThanOrEqualTo(20));

      // All extracted candidates should be valid with properly extracted fields
      final validCandidates = candidates.where((c) => c.isValid).toList();
      expect(validCandidates.length, equals(candidates.length));

      // Verify that all 5 weekdays (Saturday, Sunday, Monday, Tuesday, Wednesday) are present
      final days = candidates.map((c) => c.dayOfWeek).toSet();
      expect(days.contains(6), isTrue); // Saturday (السبت)
      expect(days.contains(0), isTrue); // Sunday (الأحد)
      expect(days.contains(1), isTrue); // Monday (الإثنين)
      expect(days.contains(2), isTrue); // Tuesday (الثلاثاء)
      expect(days.contains(3), isTrue); // Wednesday (الأربعاء)

      // Verify core Computer Science course names are recognized
      final courseNames = candidates.map((c) => c.courseName).toSet();
      expect(courseNames.any((name) => name.contains('برمجة الويب')), isTrue);
      expect(courseNames.any((name) => name.contains('نظم تشغيل')), isTrue);
      expect(
        courseNames.any(
          (name) =>
              name.contains('الذكاء الاصطناعى') ||
              name.contains('الذكاء الاصطناعي'),
        ),
        isTrue,
      );
      expect(courseNames.any((name) => name.contains('قواعد بيانات')), isTrue);
      expect(courseNames.any((name) => name.contains('هندسة برمجيات')), isTrue);
      expect(courseNames.any((name) => name.contains('لغة تجميع')), isTrue);

      // Verify instructors are extracted
      final instructors = candidates.map((c) => c.instructor).toSet();
      expect(
        instructors.any(
          (i) =>
              i.contains('شاديه سرحان') ||
              i.contains('نهى عبدالكريم') ||
              i.contains('ايه ايمن'),
        ),
        isTrue,
      );

      // Verify rooms are extracted
      final rooms = candidates.map((c) => c.room).toSet();
      expect(
        rooms.any(
          (r) => r.contains('معمل') || r.contains('مدرج') || r.contains('قاعة'),
        ),
        isTrue,
      );

      // Verify all candidates have valid start and end time ranges
      for (final c in candidates) {
        expect(c.isTimeRangeValid, isTrue);
        expect(c.isTimeRangeReversed, isFalse);
        expect(c.validationErrors, isEmpty);
      }
    },
  );
}
