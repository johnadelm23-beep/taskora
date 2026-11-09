import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/notification/notification_id_generator.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

class FakeNotificationService implements NotificationService {
  final List<ScheduledCall> scheduled = [];
  final List<int> cancelled = [];
  bool allCancelled = false;
  late tz.Location _location;

  FakeNotificationService() {
    tz_data.initializeTimeZones();
    _location = tz.UTC;
  }

  @override
  tz.Location get localLocation => _location;

  @override
  Stream<String> get onNotificationTapped => const Stream.empty();

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
  }

  @override
  Future<void> cancelAll() async {
    allCancelled = true;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> arePermissionsGranted() async => true;

  @override
  Future<bool> requestPermissions() async => true;

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
  }) async {
    scheduled.add(
      ScheduledCall(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      ),
    );
  }
}

class ScheduledCall {
  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final DateTimeComponents? matchDateTimeComponents;
  final String? payload;

  ScheduledCall({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    this.matchDateTimeComponents,
    this.payload,
  });
}

class FakePreferencesService implements PreferencesService {
  ThemeMode themeMode = ThemeMode.system;
  Locale? locale;
  bool lectureReminders = true;
  bool taskReminders = true;

  @override
  Locale? getLocale() => locale;

  @override
  ThemeMode getThemeMode() => themeMode;

  @override
  bool getLectureRemindersEnabled() => lectureReminders;

  @override
  bool getTaskRemindersEnabled() => taskReminders;

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

class FakeScheduleRepository implements ScheduleRepository {
  List<LectureEntity> lectures = [];

  @override
  Future<int> addLecture(LectureEntity lecture) async {
    lectures.add(lecture);
    return lecture.id;
  }

  @override
  Future<int> deleteLecture(int id) async {
    final count = lectures.where((l) => l.id == id).length;
    lectures.removeWhere((l) => l.id == id);
    return count;
  }

  @override
  Future<LectureEntity?> findConflictingLecture(LectureEntity lecture) async =>
      null;

  @override
  Future<List<LectureEntity>> getAllLectures() async => lectures;

  @override
  Future<List<LectureEntity>> getLecturesForDay(int dayOfWeek) async =>
      lectures.where((l) => l.dayOfWeek == dayOfWeek).toList();

  @override
  Future<bool> updateLecture(LectureEntity lecture) async {
    final idx = lectures.indexWhere((l) => l.id == lecture.id);
    if (idx != -1) {
      lectures[idx] = lecture;
      return true;
    }
    return false;
  }

  @override
  Stream<List<LectureEntity>> watchAllLectures() => Stream.value(lectures);

  @override
  Stream<List<LectureEntity>> watchLecturesForDay(int dayOfWeek) =>
      Stream.value(lectures.where((l) => l.dayOfWeek == dayOfWeek).toList());
}

class FakeTaskRepository implements TaskRepository {
  List<TaskEntity> tasks = [];

  @override
  Future<int> createTask(TaskEntity task) async {
    tasks.add(task);
    return task.id;
  }

  @override
  Future<bool> deleteTask(int id) async {
    final count = tasks.where((t) => t.id == id).length;
    tasks.removeWhere((t) => t.id == id);
    return count > 0;
  }

  @override
  Future<List<TaskEntity>> getAllTasks() async => tasks;

  @override
  Future<TaskEntity?> getTaskById(int id) async {
    try {
      return tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> toggleTaskCompletion(int id, bool isCompleted) async {
    final idx = tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      tasks[idx] = tasks[idx].copyWith(isCompleted: isCompleted);
      return true;
    }
    return false;
  }

  @override
  Future<bool> updateTask(TaskEntity task) async {
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      tasks[idx] = task;
      return true;
    }
    return false;
  }

  @override
  Stream<List<TaskEntity>> watchAllTasks() => Stream.value(tasks);

  @override
  Stream<List<TaskEntity>> watchCompletedTasks() =>
      Stream.value(tasks.where((t) => t.isCompleted).toList());

  @override
  Stream<List<TaskEntity>> watchPendingTasks() =>
      Stream.value(tasks.where((t) => !t.isCompleted).toList());
}

void main() {
  tz_data.initializeTimeZones();
  final utc = tz.UTC;

  group('NotificationIdGenerator', () {
    test('generates collision-free IDs for lectures and tasks', () {
      final lectureId1 = NotificationIdGenerator.forLecture(1);
      final lectureId2 = NotificationIdGenerator.forLecture(2);
      final taskId1 = NotificationIdGenerator.forTask(1);
      final taskId2 = NotificationIdGenerator.forTask(2);

      expect(lectureId1, equals(1000001));
      expect(lectureId2, equals(1000002));
      expect(taskId1, equals(2000001));
      expect(taskId2, equals(2000002));

      expect(NotificationIdGenerator.isLecture(lectureId1), isTrue);
      expect(NotificationIdGenerator.isTask(lectureId1), isFalse);

      expect(NotificationIdGenerator.isTask(taskId1), isTrue);
      expect(NotificationIdGenerator.isLecture(taskId1), isFalse);
    });
  });

  group('ReminderSchedulerImpl - Pure Calculations', () {
    test(
      'calculates lecture reminder 15 minutes before start time on same day',
      () {
        // Mock current time: Sunday 2026-10-25 08:00 UTC
        final now = DateTime.utc(2026, 10, 25, 8, 0);
        // Lecture on Sunday (day 0) at 09:00
        final scheduled = ReminderSchedulerImpl.nextInstanceOfLectureReminder(
          dayOfWeek: 0,
          startTime: '09:00',
          location: utc,
          now: now,
        );

        // Reminder should be Sunday 2026-10-25 at 08:45
        expect(scheduled.year, equals(2026));
        expect(scheduled.month, equals(10));
        expect(scheduled.day, equals(25));
        expect(scheduled.hour, equals(8));
        expect(scheduled.minute, equals(45));
      },
    );

    test(
      'pushes to next week if scheduled lecture time has already passed today',
      () {
        // Current time: Sunday 2026-10-25 09:30 UTC
        final now = DateTime.utc(2026, 10, 25, 9, 30);
        // Lecture on Sunday (day 0) at 09:00 (reminder would have been 08:45, already passed)
        final scheduled = ReminderSchedulerImpl.nextInstanceOfLectureReminder(
          dayOfWeek: 0,
          startTime: '09:00',
          location: utc,
          now: now,
        );

        // Should be scheduled for next Sunday: 2026-11-01 at 08:45
        expect(scheduled.year, equals(2026));
        expect(scheduled.month, equals(11));
        expect(scheduled.day, equals(1));
        expect(scheduled.hour, equals(8));
        expect(scheduled.minute, equals(45));
      },
    );

    test(
      'handles midnight boundary correctly (rolls 15 minutes back to previous day)',
      () {
        // Current time: Saturday 2026-10-24 12:00 UTC
        final now = DateTime.utc(2026, 10, 24, 12, 0);
        // Lecture on Sunday (day 0) at 00:10
        final scheduled = ReminderSchedulerImpl.nextInstanceOfLectureReminder(
          dayOfWeek: 0,
          startTime: '00:10',
          location: utc,
          now: now,
        );

        // 15 min before Sunday 00:10 is Saturday 23:55
        expect(scheduled.day, equals(24)); // Saturday
        expect(scheduled.hour, equals(23));
        expect(scheduled.minute, equals(55));
      },
    );

    test(
      'calculates task reminder 1 hour before due date when deadline is far',
      () {
        final now = DateTime(2026, 10, 29, 10, 0);
        final dueDate = DateTime(2026, 10, 29, 14, 0); // 4 hours away

        final reminderTime = ReminderSchedulerImpl.calculateTaskReminderTime(
          dueDate: dueDate,
          isCompleted: false,
          now: now,
        );

        expect(reminderTime, equals(DateTime(2026, 10, 29, 13, 0)));
      },
    );

    test(
      'calculates task reminder at deadline when due date is less than 1 hour away',
      () {
        final now = DateTime(2026, 10, 29, 10, 0);
        final dueDate = DateTime(2026, 10, 29, 10, 30); // 30 minutes away

        final reminderTime = ReminderSchedulerImpl.calculateTaskReminderTime(
          dueDate: dueDate,
          isCompleted: false,
          now: now,
        );

        expect(reminderTime, equals(dueDate));
      },
    );

    test(
      'returns null for completed task or task without due date or overdue task',
      () {
        final now = DateTime(2026, 10, 29, 10, 0);

        // Completed task
        expect(
          ReminderSchedulerImpl.calculateTaskReminderTime(
            dueDate: DateTime(2026, 10, 29, 14, 0),
            isCompleted: true,
            now: now,
          ),
          isNull,
        );

        // Null due date
        expect(
          ReminderSchedulerImpl.calculateTaskReminderTime(
            dueDate: null,
            isCompleted: false,
            now: now,
          ),
          isNull,
        );

        // Overdue task
        expect(
          ReminderSchedulerImpl.calculateTaskReminderTime(
            dueDate: DateTime(2026, 10, 29, 9, 0),
            isCompleted: false,
            now: now,
          ),
          isNull,
        );
      },
    );
  });

  group('ReminderSchedulerImpl - Integration with Service', () {
    late FakeNotificationService notificationService;
    late FakePreferencesService preferencesService;
    late FakeScheduleRepository scheduleRepo;
    late FakeTaskRepository taskRepo;
    late ReminderSchedulerImpl scheduler;

    setUp(() {
      notificationService = FakeNotificationService();
      preferencesService = FakePreferencesService();
      scheduleRepo = FakeScheduleRepository();
      taskRepo = FakeTaskRepository();

      scheduler = ReminderSchedulerImpl(
        notificationService: notificationService,
        preferencesService: preferencesService,
        scheduleRepository: scheduleRepo,
        taskRepository: taskRepo,
      );
    });

    test(
      'schedules English lecture reminder when preferences enabled',
      () async {
        preferencesService.locale = const Locale('en');
        final lecture = const LectureEntity(
          id: 42,
          courseName: 'Algorithms',
          dayOfWeek: 1, // Monday
          startTime: '10:00',
          endTime: '11:30',
          room: 'Hall 101',
        );

        await scheduler.scheduleLectureReminder(lecture);

        expect(notificationService.scheduled.length, equals(1));
        final call = notificationService.scheduled.first;
        expect(call.id, equals(1000042));
        expect(call.title, contains('Upcoming Class: Algorithms'));
        expect(call.body, contains('Starts in 15 minutes (10:00)'));
        expect(call.body, contains('Hall 101'));
        expect(
          call.matchDateTimeComponents,
          equals(DateTimeComponents.dayOfWeekAndTime),
        );
        expect(call.payload, equals('schedule:42'));
      },
    );

    test('schedules Arabic lecture reminder when locale is Arabic', () async {
      preferencesService.locale = const Locale('ar');
      final lecture = const LectureEntity(
        id: 7,
        courseName: 'خوارزميات',
        dayOfWeek: 0,
        startTime: '09:00',
        endTime: '10:30',
        room: 'معمل 2',
      );

      await scheduler.scheduleLectureReminder(lecture);

      expect(notificationService.scheduled.length, equals(1));
      final call = notificationService.scheduled.first;
      expect(call.id, equals(1000007));
      expect(call.title, contains('محاضرة قادمة: خوارزميات'));
      expect(call.body, contains('تبدأ خلال 15 دقيقة'));
      expect(call.body, contains('معمل 2'));
    });

    test(
      'does not schedule lecture reminder when disabled in preferences',
      () async {
        preferencesService.lectureReminders = false;
        final lecture = const LectureEntity(
          id: 1,
          courseName: 'CS',
          dayOfWeek: 1,
          startTime: '10:00',
          endTime: '11:30',
        );

        await scheduler.scheduleLectureReminder(lecture);
        expect(notificationService.scheduled, isEmpty);
      },
    );

    test('cancels lecture reminder with deterministic ID', () async {
      await scheduler.cancelLectureReminder(15);
      expect(notificationService.cancelled, contains(1000015));
    });

    test('schedules task reminder when due in future', () async {
      preferencesService.locale = const Locale('en');
      final futureDue = DateTime.now().add(const Duration(hours: 3));
      final task = TaskEntity(
        id: 10,
        title: 'Project Submission',
        dueDate: futureDue,
        isCompleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await scheduler.scheduleTaskReminder(task);

      expect(notificationService.scheduled.length, equals(1));
      final call = notificationService.scheduled.first;
      expect(call.id, equals(2000010));
      expect(call.title, contains('Task Due Soon: Project Submission'));
      expect(call.payload, equals('tasks:10'));
    });

    test('cancels task reminder with deterministic ID', () async {
      await scheduler.cancelTaskReminder(88);
      expect(notificationService.cancelled, contains(2000088));
    });

    test(
      'resyncAllReminders re-schedules active lectures and pending tasks',
      () async {
        scheduleRepo.lectures = [
          const LectureEntity(
            id: 1,
            courseName: 'Math',
            dayOfWeek: 2,
            startTime: '08:00',
            endTime: '09:30',
          ),
        ];
        taskRepo.tasks = [
          TaskEntity(
            id: 5,
            title: 'Homework 1',
            dueDate: DateTime.now().add(const Duration(days: 2)),
            isCompleted: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          TaskEntity(
            id: 6,
            title: 'Finished Task',
            dueDate: DateTime.now().add(const Duration(days: 2)),
            isCompleted: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        await scheduler.resyncAllReminders();

        // Should schedule lecture 1 and task 5, but NOT completed task 6
        expect(notificationService.scheduled.length, equals(2));
        expect(
          notificationService.scheduled.any((s) => s.id == 1000001),
          isTrue,
        );
        expect(
          notificationService.scheduled.any((s) => s.id == 2000005),
          isTrue,
        );
        expect(
          notificationService.scheduled.any((s) => s.id == 2000006),
          isFalse,
        );
      },
    );
  });
}
