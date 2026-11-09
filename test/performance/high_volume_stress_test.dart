import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/backup/backup_service.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

class MockReminderScheduler implements ReminderScheduler {
  int resyncCount = 0;

  @override
  Future<void> resyncAllReminders() async {
    resyncCount++;
  }

  @override
  Future<void> cancelAllLectureReminders() async {}

  @override
  Future<void> cancelAllTaskReminders() async {}

  @override
  Future<void> cancelLectureReminder(int lectureId) async {}

  @override
  Future<void> cancelTaskReminder(int taskId) async {}

  @override
  Future<void> rescheduleLectureReminder(LectureEntity lecture) async {}

  @override
  Future<void> rescheduleTaskReminder(TaskEntity task) async {}

  @override
  Future<void> scheduleLectureReminder(LectureEntity lecture) async {}

  @override
  Future<void> scheduleTaskReminder(TaskEntity task) async {}
}

void main() {
  late AppDatabase db;
  late ScheduleRepository scheduleRepo;
  late TaskRepository taskRepo;
  late MockReminderScheduler mockReminderScheduler;
  late BackupService backupService;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    scheduleRepo = ScheduleRepositoryImpl(db);
    taskRepo = TaskRepositoryImpl(db);
    mockReminderScheduler = MockReminderScheduler();
    backupService = BackupServiceImpl(
      database: db,
      scheduleRepository: scheduleRepo,
      taskRepository: taskRepo,
      reminderScheduler: mockReminderScheduler,
    );
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'High volume data safety & query performance (70 lectures, 150 tasks)',
    () async {
      final stopwatch = Stopwatch()..start();

      // 1. Seed 70 lectures (10 per day across 7 days: 0 = Mon to 6 = Sun)
      for (int day = 0; day < 7; day++) {
        for (int slot = 0; slot < 10; slot++) {
          final startHour = 8 + slot;
          final startHourStr = startHour.toString().padLeft(2, '0');
          final endHourStr = startHour.toString().padLeft(2, '0');
          final courseName = (slot % 2 == 0)
              ? 'Course $day-$slot English'
              : 'مادة $day-$slot عربي';

          await db
              .into(db.lectures)
              .insert(
                LecturesCompanion.insert(
                  courseName: courseName,
                  dayOfWeek: day,
                  startTime: '$startHourStr:00',
                  endTime: '$endHourStr:45',
                  instructor: drift.Value('Dr. Professor $slot'),
                  room: drift.Value('Hall ${day * 10 + slot}'),
                  colorHex: const drift.Value(0xFF1976D2),
                ),
              );
        }
      }

      // 2. Seed 150 tasks (50 Low, 50 Medium, 50 High; 75 completed, 75 pending)
      for (int i = 0; i < 150; i++) {
        final priority = (i % 3 == 0)
            ? 2
            : (i % 3 == 1)
            ? 1
            : 0;
        final isDone = i % 2 == 0;
        final title = (i % 2 == 0)
            ? 'Task $i English Assignment'
            : 'مهمة $i باللغة العربية';

        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                title: title,
                priority: drift.Value(priority),
                dueDate: drift.Value(
                  DateTime.now().add(Duration(days: (i % 14) + 1)),
                ),
                isCompleted: drift.Value(isDone),
              ),
            );
      }

      final insertDuration = stopwatch.elapsedMilliseconds;
      expect(insertDuration, isNonZero);

      // 3. Query performance verification
      final queryStopwatch = Stopwatch()..start();

      final allLectures = await scheduleRepo.getAllLectures();
      expect(allLectures.length, equals(70));

      for (int day = 0; day < 7; day++) {
        final dayLectures = await scheduleRepo.getLecturesForDay(day);
        expect(dayLectures.length, equals(10));
      }

      final allTasks = await taskRepo.watchAllTasks().first;
      expect(allTasks.length, equals(150));
      final completedTasks = allTasks.where((t) => t.isCompleted).length;
      final pendingTasks = allTasks.where((t) => !t.isCompleted).length;
      expect(completedTasks, equals(75));
      expect(pendingTasks, equals(75));

      final queryDuration = queryStopwatch.elapsedMilliseconds;
      // High-volume queries must complete well within real-time budget (< 500ms)
      expect(queryDuration, lessThan(500));

      // 4. Round-trip backup & restore with high-volume dataset
      final backupJson = await backupService.createBackupJson();
      final parsedPayload = backupService.parseAndValidateJson(backupJson);

      expect(parsedPayload.lectures.length, equals(70));
      expect(parsedPayload.tasks.length, equals(150));

      // Wipe the database tables completely
      await db.delete(db.lectures).go();
      await db.delete(db.tasks).go();

      expect((await scheduleRepo.getAllLectures()).isEmpty, isTrue);
      expect((await taskRepo.watchAllTasks().first).isEmpty, isTrue);

      // Atomically restore full dataset
      await backupService.restoreBackup(parsedPayload);

      // Verify complete data survivability
      final restoredLectures = await scheduleRepo.getAllLectures();
      final restoredTasks = await taskRepo.watchAllTasks().first;

      expect(restoredLectures.length, equals(70));
      expect(restoredTasks.length, equals(150));
      expect(mockReminderScheduler.resyncCount, equals(1));

      // Verify lectures preserved Arabic and English
      expect(restoredLectures.first.courseName, equals('Course 0-0 English'));
      expect(restoredLectures[1].courseName, equals('مادة 0-1 عربي'));
      expect(restoredLectures.first.startTime, equals('08:00'));
      expect(restoredLectures.first.endTime, equals('08:45'));

      // Verify tasks retained completion status & priorities
      final restoredCompleted = restoredTasks
          .where((t) => t.isCompleted)
          .length;
      final restoredPending = restoredTasks.where((t) => !t.isCompleted).length;
      expect(restoredCompleted, equals(75));
      expect(restoredPending, equals(75));
    },
  );
}
