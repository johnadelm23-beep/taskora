import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/backup/backup_payload.dart';
import 'package:taskora/core/backup/backup_service.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class MockBackupService implements BackupService {
  BackupPayload? pickedPayload;
  int restoreCount = 0;
  int backupCallCount = 0;

  @override
  Future<String> createBackupJson() async {
    backupCallCount++;
    return '{"app": "Taskora", "version": 1}';
  }

  @override
  Future<String?> saveBackupToFile(String backupJson, {String? defaultFileName}) async {
    return '/storage/emulated/0/Download/test_backup.json';
  }

  @override
  Future<BackupPayload?> pickAndValidateBackup() async {
    return pickedPayload;
  }

  @override
  BackupPayload parseAndValidateJson(String jsonContent) {
    return BackupPayload.fromJson({});
  }

  @override
  Future<void> restoreBackup(BackupPayload payload) async {
    restoreCount++;
  }
}

class MockNotificationService implements NotificationService {
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<bool> arePermissionsGranted() async => true;
  @override
  tz.Location get localLocation => tz.getLocation('UTC');
  @override
  Future<void> scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    DateTimeComponents? matchDateTimeComponents,
    String? payload,
    String channelId = 'taskora_reminders',
    String channelName = 'Taskora Reminders',
    String channelDescription = 'General reminders from Taskora',
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) async {}
  @override
  Future<void> cancel(int id) async {}
  @override
  Future<void> cancelAll() async {}
  @override
  Stream<String> get onNotificationTapped => const Stream.empty();
}

class DummyReminderScheduler implements ReminderScheduler {
  @override
  Future<void> resyncAllReminders() async {}
  @override
  Future<void> cancelLectureReminder(int lectureId) async {}
  @override
  Future<void> cancelTaskReminder(int taskId) async {}
  @override
  Future<void> scheduleLectureReminder(LectureEntity lecture) async {}
  @override
  Future<void> scheduleTaskReminder(TaskEntity task) async {}
  @override
  Future<void> cancelAllLectureReminders() async {}
  @override
  Future<void> cancelAllTaskReminders() async {}
  @override
  Future<void> rescheduleLectureReminder(LectureEntity lecture) async {}
  @override
  Future<void> rescheduleTaskReminder(TaskEntity task) async {}
}

void main() {
  late MockBackupService mockBackupService;
  late AppDatabase database;

  setUp(() async {
    tz_data.initializeTimeZones();
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sp);
    sl.registerLazySingleton<PreferencesService>(() => PreferencesServiceImpl(sp));

    database = AppDatabase(NativeDatabase.memory());
    sl.registerLazySingleton<AppDatabase>(() => database);
    sl.registerLazySingleton<NotificationService>(() => MockNotificationService());
    sl.registerLazySingleton<ScheduleRepository>(() => ScheduleRepositoryImpl(database));
    sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(database));
    sl.registerLazySingleton<ReminderScheduler>(() => DummyReminderScheduler());

    mockBackupService = MockBackupService();
    sl.registerLazySingleton<BackupService>(() => mockBackupService);

    sl.registerFactory<ThemeCubit>(() => ThemeCubit(sl()));
    sl.registerFactory<LocaleCubit>(() => LocaleCubit(sl()));
    sl.registerFactory<RemindersCubit>(() => RemindersCubit(
          notificationService: sl(),
          preferencesService: sl(),
          reminderScheduler: sl(),
        ));
    sl.registerFactory<ScheduleCubit>(() => ScheduleCubit(sl(), sl()));
  });

  tearDown(() async {
    await database.close();
    await sl.reset();
  });

  Widget buildSettingsScreen() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<RemindersCubit>(create: (_) => sl<RemindersCubit>()),
        BlocProvider<ScheduleCubit>(create: (_) => sl<ScheduleCubit>()),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en'), Locale('ar')],
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('SettingsScreen displays Backup and Restore options and triggers confirmation dialog', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildSettingsScreen());
    await tester.pumpAndSettle();

    // Scroll down to Storage & Privacy section
    await tester.scrollUntilVisible(
      find.text('Backup Database'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Tiles exist
    expect(find.text('Backup Database'), findsOneWidget);
    expect(find.text('Restore Database'), findsOneWidget);

    // 1. Test Backup Tap
    await tester.tap(find.text('Backup Database'));
    await tester.pumpAndSettle();
    expect(mockBackupService.backupCallCount, equals(1));
    expect(find.text('Backup successfully saved!'), findsOneWidget);

    // 2. Test Restore Tap with confirmation
    mockBackupService.pickedPayload = BackupPayload(
      exportedAt: DateTime.now(),
      schemaVersion: 3,
      lectures: [
        const LectureEntity(
          id: 1,
          courseName: 'Physics',
          dayOfWeek: 0,
          startTime: '08:00',
          endTime: '09:30',
        ),
      ],
      tasks: [
        TaskEntity(
          id: 1,
          title: 'Lab Report',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ],
    );

    await tester.tap(find.text('Restore Database'));
    await tester.pumpAndSettle();

    // Verify Confirmation Dialog appears
    expect(find.text('Restore from Backup?'), findsOneWidget);
    expect(find.textContaining('Found 1 lectures and 1 tasks'), findsOneWidget);
    expect(find.text('Restore & Overwrite'), findsOneWidget);

    // Tap Restore & Overwrite
    await tester.tap(find.text('Restore & Overwrite'));
    await tester.pumpAndSettle();

    // Verify restore was executed
    expect(mockBackupService.restoreCount, equals(1));
    expect(find.textContaining('Database successfully restored!'), findsOneWidget);
  });
}
