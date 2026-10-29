import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/app.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_theme.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/widgets/feature_bottom_sheet.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/import_source_sheet.dart';

void main() {
  late AppDatabase testDb;

  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    testDb = AppDatabase(NativeDatabase.memory());
    await initDependencies(customDatabase: testDb);
  });

  tearDown(() async {
    await testDb.close();
  });

  Widget buildTestWidget({
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme ?? AppTheme.darkTheme,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  FeatureBottomSheet.show(
                    context,
                    icon: Icons.document_scanner_outlined,
                    title: l10n.importSheetTitle,
                    description: l10n.importSheetDesc,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          );
        },
      ),
    );
  }

  group('Import Schedule FeatureBottomSheet', () {
    testWidgets(
      'displays title, Coming Soon subtitle, updated description, and Got it button in English',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Open bottom sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        expect(find.byType(FeatureBottomSheet), findsOneWidget);
        expect(find.text('Import Schedule'), findsOneWidget);
        expect(find.text('Coming Soon'), findsOneWidget);
        expect(
          find.textContaining('This feature is planned for a future update'),
          findsOneWidget,
        );
        // Ensure no obsolete Phase 3 claims
        expect(find.textContaining('Phase 3'), findsNothing);
        expect(find.text('Got it'), findsOneWidget);

        // Tap 'Got it' and verify bottom sheet closes
        await tester.tap(find.text('Got it'));
        await tester.pumpAndSettle();
        expect(find.byType(FeatureBottomSheet), findsNothing);
      },
    );

    testWidgets('displays localized Arabic RTL content and closes with حسناً', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(locale: const Locale('ar')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(FeatureBottomSheet), findsOneWidget);
      expect(find.text('استيراد الجدول الدراسي'), findsOneWidget);
      expect(find.text('قادمة قريباً'), findsOneWidget);
      expect(
        find.textContaining('ستتوفر هذه الميزة في تحديث قادم'),
        findsOneWidget,
      );
      expect(find.textContaining('المرحلة 3'), findsNothing);
      expect(find.text('حسناً'), findsOneWidget);

      // Verify Directionality is RTL
      expect(
        Directionality.of(tester.element(find.byType(FeatureBottomSheet))),
        TextDirection.rtl,
      );

      // Tap 'حسناً' and verify it closes
      await tester.tap(find.text('حسناً'));
      await tester.pumpAndSettle();
      expect(find.byType(FeatureBottomSheet), findsNothing);
    });

    testWidgets('renders properly with Light Theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(theme: AppTheme.lightTheme));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(FeatureBottomSheet), findsOneWidget);
      expect(find.text('Import Schedule'), findsOneWidget);
      expect(find.text('Coming Soon'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(FeatureBottomSheet), findsNothing);
    });

    testWidgets(
      'triggers ImportSourceSheet from Schedule screen app bar action',
      (WidgetTester tester) async {
        await tester.pumpWidget(const TaskoraApp());
        await tester.pumpAndSettle();

        // Go to Schedule tab
        await tester.tap(find.byIcon(Icons.calendar_month_outlined));
        await tester.pumpAndSettle();

        // Tap document scanner icon in app bar
        await tester.tap(find.byIcon(Icons.document_scanner_outlined).first);
        await tester.pumpAndSettle();

        expect(find.byType(ImportSourceSheet), findsOneWidget);
        expect(find.text('Select Schedule Document'), findsOneWidget);
        expect(find.text('Choose from Gallery'), findsOneWidget);
        expect(find.text('Take Photo with Camera'), findsOneWidget);
        expect(find.text('Import from PDF Document'), findsOneWidget);

        // Tap back / dismiss
        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();

        expect(find.byType(ImportSourceSheet), findsNothing);

        // Clean unmount
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      },
    );
  });
}
