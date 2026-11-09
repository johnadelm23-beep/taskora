import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:taskora/core/notification/notification_id_generator.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:timezone/timezone.dart' as tz;

abstract class ReminderScheduler {
  Future<void> scheduleLectureReminder(LectureEntity lecture);
  Future<void> cancelLectureReminder(int lectureId);
  Future<void> rescheduleLectureReminder(LectureEntity lecture);

  Future<void> scheduleTaskReminder(TaskEntity task);
  Future<void> cancelTaskReminder(int taskId);
  Future<void> rescheduleTaskReminder(TaskEntity task);

  Future<void> cancelAllLectureReminders();
  Future<void> cancelAllTaskReminders();
  Future<void> resyncAllReminders();
}

class ReminderSchedulerImpl implements ReminderScheduler {
  final NotificationService notificationService;
  final PreferencesService preferencesService;
  final ScheduleRepository scheduleRepository;
  final TaskRepository taskRepository;

  ReminderSchedulerImpl({
    required this.notificationService,
    required this.preferencesService,
    required this.scheduleRepository,
    required this.taskRepository,
  });

  /// Pure calculation of next instance for a weekly recurring lecture reminder (15 minutes prior).
  static tz.TZDateTime nextInstanceOfLectureReminder({
    required int dayOfWeek, // 0: Sunday ... 6: Saturday
    required String startTime, // "HH:mm" (24-hour)
    required tz.Location location,
    DateTime? now,
  }) {
    final current = now != null
        ? tz.TZDateTime.from(now, location)
        : tz.TZDateTime.now(location);

    final parts = startTime.split(':');
    final lectureHour = int.parse(parts[0]);
    final lectureMinute = int.parse(parts[1]);

    // Target weekday in ISO standard (1: Monday ... 7: Sunday)
    final targetIsoWeekday = dayOfWeek == 0 ? DateTime.sunday : dayOfWeek;

    // Calculate 15 minutes before lecture time
    var reminderHour = lectureHour;
    var reminderMinute = lectureMinute - 15;
    var dayOffset = 0;

    if (reminderMinute < 0) {
      reminderMinute += 60;
      reminderHour -= 1;
      if (reminderHour < 0) {
        reminderHour += 24;
        dayOffset = -1; // crossed midnight backwards
      }
    }

    var effectiveIsoWeekday = targetIsoWeekday + dayOffset;
    if (effectiveIsoWeekday < DateTime.monday) {
      effectiveIsoWeekday = DateTime.sunday;
    } else if (effectiveIsoWeekday > DateTime.sunday) {
      effectiveIsoWeekday = DateTime.monday;
    }

    var daysUntil = effectiveIsoWeekday - current.weekday;
    if (daysUntil < 0) {
      daysUntil += 7;
    }

    var scheduledDate = tz.TZDateTime(
      location,
      current.year,
      current.month,
      current.day + daysUntil,
      reminderHour,
      reminderMinute,
    );

    // If the scheduled reminder time for today has already passed, push to next week
    if (scheduledDate.isBefore(current)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  /// Pure calculation of reminder trigger time for a task deadline.
  /// Sensible default: 1 hour before due date, or exactly at due date if <1h away.
  static DateTime? calculateTaskReminderTime({
    required DateTime? dueDate,
    required bool isCompleted,
    DateTime? now,
  }) {
    if (dueDate == null || isCompleted) return null;
    final current = now ?? DateTime.now();
    if (dueDate.isBefore(current)) return null;

    final oneHourBefore = dueDate.subtract(const Duration(hours: 1));
    if (oneHourBefore.isAfter(current)) {
      return oneHourBefore;
    }
    return dueDate;
  }

  bool get _isArabic {
    final locale = preferencesService.getLocale();
    return locale?.languageCode == 'ar';
  }

  @override
  Future<void> scheduleLectureReminder(LectureEntity lecture) async {
    if (!preferencesService.getLectureRemindersEnabled()) return;

    try {
      final scheduledDate = nextInstanceOfLectureReminder(
        dayOfWeek: lecture.dayOfWeek,
        startTime: lecture.startTime,
        location: notificationService.localLocation,
      );

      final isAr = _isArabic;
      final title = isAr
          ? 'محاضرة قادمة: ${lecture.courseName}'
          : 'Upcoming Class: ${lecture.courseName}';

      final locationInfo = lecture.room.isNotEmpty
          ? (isAr ? ' • ${lecture.room}' : ' • ${lecture.room}')
          : '';

      final body = isAr
          ? 'تبدأ خلال 15 دقيقة (${lecture.startTime})$locationInfo'
          : 'Starts in 15 minutes (${lecture.startTime})$locationInfo';

      final notificationId = NotificationIdGenerator.forLecture(lecture.id);

      await notificationService.scheduleZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'schedule:${lecture.id}',
        channelId: NotificationServiceImpl.lectureChannelId,
        channelName: NotificationServiceImpl.lectureChannelName,
        channelDescription: NotificationServiceImpl.lectureChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
      );
    } catch (_) {
      // Safe error containment
    }
  }

  @override
  Future<void> cancelLectureReminder(int lectureId) async {
    final notificationId = NotificationIdGenerator.forLecture(lectureId);
    await notificationService.cancel(notificationId);
  }

  @override
  Future<void> rescheduleLectureReminder(LectureEntity lecture) async {
    await cancelLectureReminder(lecture.id);
    await scheduleLectureReminder(lecture);
  }

  @override
  Future<void> scheduleTaskReminder(TaskEntity task) async {
    if (!preferencesService.getTaskRemindersEnabled()) return;
    if (task.isCompleted || task.dueDate == null) return;

    final reminderTime = calculateTaskReminderTime(
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
    );

    if (reminderTime == null) return;

    try {
      final scheduledDate = tz.TZDateTime.from(
        reminderTime,
        notificationService.localLocation,
      );

      final isAr = _isArabic;
      final title = isAr
          ? 'موعد تسليم مهمة: ${task.title}'
          : 'Task Due Soon: ${task.title}';

      final dueFormatted = DateFormat('jm').format(task.dueDate!.toLocal());
      final courseInfo =
          (task.courseName != null && task.courseName!.isNotEmpty)
          ? (isAr ? ' • ${task.courseName}' : ' • ${task.courseName}')
          : '';

      final body = isAr
          ? 'موعد التسليم: $dueFormatted$courseInfo'
          : 'Deadline at $dueFormatted$courseInfo';

      final notificationId = NotificationIdGenerator.forTask(task.id);

      await notificationService.scheduleZoned(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: 'tasks:${task.id}',
        channelId: NotificationServiceImpl.taskChannelId,
        channelName: NotificationServiceImpl.taskChannelName,
        channelDescription: NotificationServiceImpl.taskChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
      );
    } catch (_) {
      // Safe error containment
    }
  }

  @override
  Future<void> cancelTaskReminder(int taskId) async {
    final notificationId = NotificationIdGenerator.forTask(taskId);
    await notificationService.cancel(notificationId);
  }

  @override
  Future<void> rescheduleTaskReminder(TaskEntity task) async {
    await cancelTaskReminder(task.id);
    await scheduleTaskReminder(task);
  }

  @override
  Future<void> cancelAllLectureReminders() async {
    final lectures = await scheduleRepository.getAllLectures();
    for (final l in lectures) {
      await cancelLectureReminder(l.id);
    }
  }

  @override
  Future<void> cancelAllTaskReminders() async {
    final tasks = await taskRepository.getAllTasks();
    for (final t in tasks) {
      await cancelTaskReminder(t.id);
    }
  }

  @override
  Future<void> resyncAllReminders() async {
    // 1. Lectures
    if (preferencesService.getLectureRemindersEnabled()) {
      final lectures = await scheduleRepository.getAllLectures();
      for (final lecture in lectures) {
        await scheduleLectureReminder(lecture);
      }
    } else {
      await cancelAllLectureReminders();
    }

    // 2. Tasks
    if (preferencesService.getTaskRemindersEnabled()) {
      final tasks = await taskRepository.getAllTasks();
      for (final task in tasks) {
        if (!task.isCompleted && task.dueDate != null) {
          await scheduleTaskReminder(task);
        }
      }
    } else {
      await cancelAllTaskReminders();
    }
  }
}
