import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_theme.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';
import 'package:taskora/features/import_schedule/domain/services/text_extractor_service.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/import_schedule/presentation/screens/import_review_screen.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/candidate_lecture_card.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/edit_candidate_sheet.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';

class MockTextExtractor implements TextExtractorService {
  @override
  Future<String> extractTextFromImage(String imagePath) async => '';

  @override
  Future<String> extractTextFromPdf(String pdfPath) async => '';
}

void main() {
  late AppDatabase db;
  late ScheduleRepository repository;
  late TimetableParser parser;
  late MockTextExtractor mockExtractor;
  late ImportScheduleCubit importCubit;
  late NavigationCubit navCubit;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    await initDependencies(customDatabase: db);
    repository = sl<ScheduleRepository>();
    parser = sl<TimetableParser>();
    mockExtractor = MockTextExtractor();
    importCubit = ImportScheduleCubit(
      textExtractor: mockExtractor,
      parser: parser,
      scheduleRepository: repository,
    );
    navCubit = sl<NavigationCubit>();
  });

  tearDown(() async {
    await importCubit.close();
    await db.close();
  });

  Widget buildTestScreen() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ImportScheduleCubit>.value(value: importCubit),
        BlocProvider<NavigationCubit>.value(value: navCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const ImportReviewScreen(),
      ),
    );
  }

  testWidgets('renders candidates list and metrics correctly', (
    WidgetTester tester,
  ) async {
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        room: 'Hall 3',
        instructor: 'Dr. John',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c2',
        courseName: 'Algorithms',
        courseCode: 'CS301',
        room: 'Lab 2',
        instructor: 'Dr. Sarah',
        dayOfWeek: 1,
        startTime: '11:00',
        endTime: '12:30',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.byType(CandidateLectureCard), findsNWidgets(2));
    expect(find.text('Data Structures'), findsOneWidget);
    expect(find.text('Algorithms'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Import Classes (2)'), findsOneWidget);
  });

  testWidgets('edits candidate course name via EditCandidateSheet', (
    WidgetTester tester,
  ) async {
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        room: 'Hall 3',
        instructor: 'Dr. John',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Data Structures'), findsOneWidget);

    // Tap edit icon
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();

    expect(find.byType(EditCandidateSheet), findsOneWidget);

    // Enter new course name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Course *'),
      'Advanced Data Structures',
    );
    await tester.pumpAndSettle();

    // Tap Save Changes
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(EditCandidateSheet), findsNothing);
    expect(find.text('Advanced Data Structures'), findsOneWidget);
  });

  testWidgets('removes candidate when delete button is tapped', (
    WidgetTester tester,
  ) async {
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c2',
        courseName: 'Algorithms',
        courseCode: 'CS301',
        dayOfWeek: 1,
        startTime: '11:00',
        endTime: '12:30',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.byType(CandidateLectureCard), findsNWidgets(2));

    // Tap delete on first card
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    expect(find.byType(CandidateLectureCard), findsOneWidget);
    expect(find.text('Algorithms'), findsOneWidget);
    expect(find.text('Data Structures'), findsNothing);
  });

  testWidgets('adds a new candidate manually', (WidgetTester tester) async {
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'c1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Tap Add Class
    await tester.tap(find.text('Add Class'));
    await tester.pumpAndSettle();

    expect(find.byType(EditCandidateSheet), findsOneWidget);

    // Fill in required name
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Course *'),
      'Computer Networks',
    );
    await tester.pumpAndSettle();

    // Save
    await tester.tap(find.text('Save Changes'));
    await tester.pumpAndSettle();

    expect(find.byType(CandidateLectureCard), findsNWidgets(2));
    expect(find.text('Computer Networks'), findsOneWidget);
  });

  testWidgets(
    'shows warning when attempting to import with incomplete fields',
    (WidgetTester tester) async {
      // Add a candidate with empty course name
      importCubit.addCandidate(
        const ExtractedLectureCandidate(
          id: 'invalid_1',
          courseName: '', // empty!
          dayOfWeek: 0,
          startTime: '09:00',
          endTime: '10:30',
        ),
      );

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Course name required'), findsOneWidget);

      // Tap import
      await tester.tap(find.text('Import Classes (1)'));
      await tester.pumpAndSettle();

      // Warning dialog should appear
      expect(find.text('Incomplete Classes'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Incomplete Classes'), findsNothing);
    },
  );

  testWidgets('detects duplicate lectures and prompts to skip duplicates', (
    WidgetTester tester,
  ) async {
    // Add existing lecture to DB
    await repository.addLecture(
      const LectureEntity(
        id: 0,
        courseName: 'Data Structures',
        courseCode: 'CS201',
        room: 'Hall 3',
        instructor: 'Dr. John',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );

    // Add candidates: one duplicate and one new
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'dup_1',
        courseName: 'Data Structures',
        courseCode: 'CS201',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
        isDuplicate: true,
      ),
    );
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'new_1',
        courseName: 'Machine Learning',
        courseCode: 'CS401',
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:30',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Already in schedule'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);

    // Tap Import Classes
    await tester.tap(find.text('Import Classes (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Duplicate Classes Found'), findsOneWidget);

    // Tap Skip Duplicates & Import
    await tester.tap(find.text('Skip Duplicates & Import'));
    await tester.pumpAndSettle();

    // Success screen
    expect(find.text('Import Completed!'), findsOneWidget);
    expect(find.text('1 existing duplicate classes skipped.'), findsOneWidget);

    // Verify DB contains both original and new lecture
    final all = await repository.getAllLectures();
    expect(all.length, 2);
    expect(all.any((l) => l.courseName == 'Machine Learning'), isTrue);
  });

  testWidgets('detects time conflict and allows user to import anyway', (
    WidgetTester tester,
  ) async {
    // Add existing lecture on Sunday 09:00 - 10:30
    await repository.addLecture(
      const LectureEntity(
        id: 0,
        courseName: 'Operating Systems',
        courseCode: 'CS302',
        room: 'Room 10',
        instructor: 'Dr. Jane',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
      ),
    );

    // Add overlapping candidate
    importCubit.addCandidate(
      const ExtractedLectureCandidate(
        id: 'conf_1',
        courseName: 'Software Engineering',
        courseCode: 'SE301',
        dayOfWeek: 0,
        startTime: '09:30',
        endTime: '11:00',
        hasConflict: true,
        conflictReason: 'Time conflict',
      ),
    );

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Overlap'), findsOneWidget);

    // Tap import
    await tester.tap(find.text('Import Classes (1)'));
    await tester.pumpAndSettle();

    expect(find.text('Time Conflict Warning'), findsOneWidget);

    // Tap Import Anyway
    await tester.tap(find.text('Import Anyway'));
    await tester.pumpAndSettle();

    expect(find.text('Import Completed!'), findsOneWidget);

    final all = await repository.getAllLectures();
    expect(all.length, 2);
  });

  testWidgets(
    'displays explanation and CSV template options when candidates are empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('No Classes Detected'), findsOneWidget);
      expect(find.text('Why did recognition fail?'), findsOneWidget);
      expect(find.text('Import CSV File'), findsOneWidget);
      expect(find.text('Download CSV Template'), findsOneWidget);
      expect(find.text('Add Class'), findsOneWidget);
      expect(find.text('Try Another File'), findsOneWidget);

      // Tap Download CSV Template to verify preview sheet appears
      await tester.tap(find.text('Download CSV Template'));
      await tester.pumpAndSettle();

      expect(find.text('Standard Timetable Format'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.text('Save CSV File'), findsOneWidget);
    },
  );
}
