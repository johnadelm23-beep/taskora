import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_theme.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/widgets/export_schedule_sheet.dart';

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          return null;
        });
  });
  Widget buildTestWidget({required List<LectureEntity> lectures}) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: ExportScheduleSheet(lectures: lectures)),
    );
  }

  group('ExportScheduleSheet Widget Tests', () {
    testWidgets('displays empty state card when lectures list is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(lectures: []));
      await tester.pumpAndSettle();

      expect(find.text('No Classes to Export'), findsOneWidget);
      expect(
        find.text(
          'Your schedule is currently empty. Add classes before exporting your timetable.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'displays preview, language toggle, and action buttons for saved lectures',
      (WidgetTester tester) async {
        final sampleLectures = [
          const LectureEntity(
            id: 1,
            courseName: 'Algorithms',
            courseCode: 'CS201',
            dayOfWeek: 0,
            startTime: '09:00',
            endTime: '10:30',
            instructor: 'Dr. Alan',
            room: 'Hall 1',
            notes: 'Important class',
          ),
          const LectureEntity(
            id: 2,
            courseName: 'Operating Systems',
            courseCode: 'CS302',
            dayOfWeek: 1,
            startTime: '11:00',
            endTime: '12:30',
            instructor: 'Dr. Linus',
            room: 'Lab 2',
          ),
        ];

        await tester.pumpWidget(buildTestWidget(lectures: sampleLectures));
        await tester.pumpAndSettle();

        expect(find.text('Export Timetable (CSV)'), findsOneWidget);
        expect(find.text('2 saved classes • UTF-8 BOM'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);
        expect(find.text('Save CSV File'), findsOneWidget);
        expect(find.text('Copy to Clipboard'), findsOneWidget);

        // Verify English preview has standard headers and course names
        expect(
          find.textContaining('Weekday,Course Name,Course Code'),
          findsOneWidget,
        );
        expect(find.textContaining('Sunday,Algorithms,CS201'), findsOneWidget);

        // Switch language to Arabic
        await tester.tap(find.text('العربية'));
        await tester.pumpAndSettle();

        // Verify Arabic preview shows Arabic headers and day names
        expect(
          find.textContaining('اليوم,اسم المقرر,كود المقرر'),
          findsOneWidget,
        );
        expect(find.textContaining('الأحد,Algorithms,CS201'), findsOneWidget);

        // Tap Copy to Clipboard
        await tester.tap(find.text('Copy to Clipboard'));
        await tester.pump();

        expect(find.text('Timetable CSV copied to clipboard!'), findsOneWidget);

        // Advance past the 2s timer
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
      },
    );
  });
}
