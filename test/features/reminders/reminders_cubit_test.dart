import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class MockNotificationService implements NotificationService {
  bool permissionsGranted = true;

  @override
  tz.Location get localLocation => tz.UTC;

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();

  @override
  Future<bool> arePermissionsGranted() async => permissionsGranted;

  @override
  Future<bool> requestPermissions() async => permissionsGranted;

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    dynamic matchDateTimeComponents,
    String? payload,
    String channelId = 'taskora_reminders',
    String channelName = 'Taskora Reminders',
    String channelDescription = 'General reminders from Taskora',
    dynamic importance,
    dynamic priority,
  }) async {}
}

class MockPreferencesService implements PreferencesService {
  bool lectureReminders = true;
  bool taskReminders = true;
  Locale? locale;
  ThemeMode themeMode = ThemeMode.system;

  @override
  bool getLectureRemindersEnabled() => lectureReminders;

  @override
  Locale? getLocale() => locale;

  @override
  bool getTaskRemindersEnabled() => taskReminders;

  @override
  ThemeMode getThemeMode() => themeMode;

  @override
  Future<void> setLectureRemindersEnabled(bool enabled) async {
    lectureReminders = enabled;
  }

  @override
  Future<void> setLocale(Locale? newLocale) async {
    locale = newLocale;
  }

  @override
  Future<void> setTaskRemindersEnabled(bool enabled) async {
    taskReminders = enabled;
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
  }
}

class MockReminderScheduler implements ReminderScheduler {
  bool resynced = false;
  bool cancelledLectures = false;
  bool cancelledTasks = false;

  @override
  Future<void> cancelAllLectureReminders() async {
    cancelledLectures = true;
  }

  @override
  Future<void> cancelAllTaskReminders() async {
    cancelledTasks = true;
  }

  @override
  Future<void> cancelLectureReminder(int lectureId) async {}

  @override
  Future<void> cancelTaskReminder(int taskId) async {}

  @override
  Future<void> rescheduleLectureReminder(LectureEntity lecture) async {}

  @override
  Future<void> rescheduleTaskReminder(TaskEntity task) async {}

  @override
  Future<void> resyncAllReminders() async {
    resynced = true;
  }

  @override
  Future<void> scheduleLectureReminder(LectureEntity lecture) async {}

  @override
  Future<void> scheduleTaskReminder(TaskEntity task) async {}
}

void main() {
  tz_data.initializeTimeZones();

  group('RemindersCubit', () {
    late MockNotificationService notificationService;
    late MockPreferencesService preferencesService;
    late MockReminderScheduler scheduler;
    late RemindersCubit cubit;

    setUp(() {
      notificationService = MockNotificationService();
      preferencesService = MockPreferencesService();
      scheduler = MockReminderScheduler();

      cubit = RemindersCubit(
        notificationService: notificationService,
        preferencesService: preferencesService,
        reminderScheduler: scheduler,
      );
    });

    tearDown(() {
      cubit.close();
    });

    test(
      'initial state reads from PreferencesService and checks permissions',
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(cubit.state.lectureRemindersEnabled, isTrue);
        expect(cubit.state.taskRemindersEnabled, isTrue);
        expect(cubit.state.hasNotificationPermission, isTrue);
      },
    );

    test(
      'toggleLectureReminders disables reminders and cancels lecture notifications',
      () async {
        await cubit.toggleLectureReminders(false);
        expect(cubit.state.lectureRemindersEnabled, isFalse);
        expect(preferencesService.lectureReminders, isFalse);
        expect(scheduler.cancelledLectures, isTrue);
      },
    );

    test(
      'toggleTaskReminders disables reminders and cancels task notifications',
      () async {
        await cubit.toggleTaskReminders(false);
        expect(cubit.state.taskRemindersEnabled, isFalse);
        expect(preferencesService.taskReminders, isFalse);
        expect(scheduler.cancelledTasks, isTrue);
      },
    );

    test('resyncAllReminders invokes scheduler resync', () async {
      await cubit.resyncAllReminders();
      expect(scheduler.resynced, isTrue);
      expect(cubit.state.isLoading, isFalse);
    });
  });
}
