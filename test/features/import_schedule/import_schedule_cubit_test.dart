import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/import_schedule/domain/services/text_extractor_service.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_state.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class MockTextExtractor implements TextExtractorService {
  String imageResult = '';
  String pdfResult = '';

  @override
  Future<String> extractTextFromImage(String imagePath) async => imageResult;

  @override
  Future<String> extractTextFromPdf(String pdfPath) async => pdfResult;
}

void main() {
  late AppDatabase database;
  late ScheduleRepository repository;
  late TimetableParser parser;
  late MockTextExtractor mockExtractor;
  late ImportScheduleCubit cubit;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = ScheduleRepositoryImpl(database);
    parser = TimetableParser();
    mockExtractor = MockTextExtractor();
    cubit = ImportScheduleCubit(
      textExtractor: mockExtractor,
      parser: parser,
      scheduleRepository: repository,
    );
  });

  tearDown(() async {
    await cubit.close();
    await database.close();
  });

  group('ImportScheduleCubit', () {
    test('initial state has status initial and empty candidates', () {
      expect(cubit.state.status, ImportStatus.initial);
      expect(cubit.state.candidates, isEmpty);
      expect(cubit.state.canConfirmImport, isFalse);
    });

    test('processRawText parses candidates and emits review status', () async {
      const text = '''
Monday
CS302 Mobile Development
Hall 4
10:00 - 11:30
''';
      await cubit.processRawText(text);

      expect(cubit.state.status, ImportStatus.review);
      expect(cubit.state.candidates.length, 1);
      final c = cubit.state.candidates.first;
      expect(c.courseCode, 'CS302');
      expect(c.dayOfWeek, 1);
      expect(c.startTime, '10:00');
      expect(c.endTime, '11:30');
      expect(cubit.state.validCount, 1);
      expect(cubit.state.canConfirmImport, isTrue);
    });

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

      // 2. Parse text with overlapping Monday class (10:30 - 12:00)
      const text = '''
Monday
CS302 Mobile Development
10:30 - 12:00
''';
      await cubit.processRawText(text);

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
        // Missing day initially
        const text = '''
Algorithms
10:00 - 11:30
''';
        await cubit.processRawText(text);
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
      () async {
        expect(cubit.state.candidates, isEmpty);
        cubit.addManualCandidate();
        expect(cubit.state.candidates.length, 1);
      },
    );

    test('removeCandidate removes item from candidate list', () async {
      const text = '''
Monday
CS101 Intro to CS
10:00 - 11:30

Tuesday
MATH201 Calculus
09:00 - 10:30
''';
      await cubit.processRawText(text);
      expect(cubit.state.candidates.length, 2);

      cubit.removeCandidate(0);
      expect(cubit.state.candidates.length, 1);
      expect(cubit.state.candidates.first.courseCode, 'MATH201');
    });

    test(
      'confirmImport saves valid candidates to database and ignores duplicates if configured',
      () async {
        const text = '''
Monday
CS101 Intro to CS
10:00 - 11:30

Tuesday
MATH201 Calculus
09:00 - 10:30
''';
        await cubit.processRawText(text);
        expect(cubit.state.canConfirmImport, isTrue);

        await cubit.confirmImport(skipDuplicates: true);

        expect(cubit.state.status, ImportStatus.success);
        expect(cubit.state.result?.importedCount, 2);
        expect(cubit.state.result?.skippedDuplicatesCount, 0);

        // Verify records exist in DB
        final dbLectures = await repository.getAllLectures();
        expect(dbLectures.length, 2);

        // Attempting to import again detects duplicates and skips them
        await cubit.processRawText(text);
        await cubit.confirmImport(skipDuplicates: true);

        expect(cubit.state.status, ImportStatus.success);
        expect(cubit.state.result?.importedCount, 0);
        expect(cubit.state.result?.skippedDuplicatesCount, 2);
        final finalDbCount = await repository.getAllLectures();
        expect(finalDbCount.length, 2); // preserved, no duplicate inflation
      },
    );

    test(
      'processCsvContent parses CSV timetable rows into candidates for review',
      () async {
        const csv = '''
Weekday,Course Name,Start Time,End Time,Instructor,Room
Monday,Algorithms,09:00 AM,10:30 AM,Dr. Alan,Lab 1
Tuesday,Operating Systems,11:00 AM,12:30 PM,Dr. Linus,Room 202
''';
        await cubit.processCsvContent(csv, fileName: 'test_timetable.csv');

        expect(cubit.state.status, ImportStatus.review);
        expect(cubit.state.sourceFileName, 'test_timetable.csv');
        expect(cubit.state.candidates.length, 2);
        expect(cubit.state.candidates[0].courseName, 'Algorithms');
        expect(cubit.state.candidates[0].startTime, '09:00');
        expect(cubit.state.candidates[0].endTime, '10:30');
        expect(cubit.state.candidates[0].isValid, isTrue);

        expect(cubit.state.candidates[1].courseName, 'Operating Systems');
        expect(cubit.state.candidates[1].startTime, '11:00');
        expect(cubit.state.candidates[1].endTime, '12:30');
        expect(cubit.state.candidates[1].isValid, isTrue);
        expect(cubit.state.canConfirmImport, isTrue);
      },
    );
  });
}
