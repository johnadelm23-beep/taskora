import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/backup/backup_payload.dart';
import 'package:taskora/core/backup/backup_service.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

class MockReminderScheduler implements ReminderScheduler {
  int resyncCallCount = 0;

  @override
  Future<void> resyncAllReminders() async {
    resyncCallCount++;
  }

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
  late AppDatabase database;
  late ScheduleRepository scheduleRepository;
  late TaskRepository taskRepository;
  late MockReminderScheduler mockReminderScheduler;
  late BackupService backupService;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    scheduleRepository = ScheduleRepositoryImpl(database);
    taskRepository = TaskRepositoryImpl(database);
    mockReminderScheduler = MockReminderScheduler();
    backupService = BackupServiceImpl(
      database: database,
      scheduleRepository: scheduleRepository,
      taskRepository: taskRepository,
      reminderScheduler: mockReminderScheduler,
    );
  });

  tearDown(() async {
    await database.close();
  });

  group('BackupPayload Validation Tests', () {
    test('serializes and parses valid payload correctly', () {
      final now = DateTime.now().toUtc();
      final payload = BackupPayload(
        exportedAt: now,
        schemaVersion: 3,
        lectures: [
          LectureEntity(
            id: 1,
            courseName: 'Algorithms',
            courseCode: 'CS201',
            room: 'Hall B',
            instructor: 'Dr. John',
            dayOfWeek: 1,
            startTime: '09:00',
            endTime: '10:30',
            notes: 'Bring slides',
            createdAt: now,
            updatedAt: now,
          ),
        ],
        tasks: [
          TaskEntity(
            id: 1,
            title: 'Project Milestone 1',
            description: 'Write project proposal',
            courseName: 'CS201',
            dueDate: now.add(const Duration(days: 3)),
            priority: TaskPriority.high,
            isCompleted: false,
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );

      final jsonMap = payload.toJson();
      expect(jsonMap['app'], equals('Taskora'));
      expect(jsonMap['version'], equals(1));
      expect(jsonMap['schemaVersion'], equals(3));
      expect(jsonMap['lectures'], hasLength(1));
      expect(jsonMap['tasks'], hasLength(1));

      final restored = BackupPayload.fromJson(jsonMap);
      expect(restored.version, equals(1));
      expect(restored.schemaVersion, equals(3));
      expect(restored.lectures.length, equals(1));
      expect(restored.lectures.first.courseName, equals('Algorithms'));
      expect(restored.lectures.first.courseCode, equals('CS201'));
      expect(restored.lectures.first.room, equals('Hall B'));
      expect(restored.lectures.first.instructor, equals('Dr. John'));
      expect(restored.lectures.first.dayOfWeek, equals(1));
      expect(restored.lectures.first.startTime, equals('09:00'));
      expect(restored.lectures.first.endTime, equals('10:30'));
      expect(restored.lectures.first.notes, equals('Bring slides'));

      expect(restored.tasks.length, equals(1));
      expect(restored.tasks.first.title, equals('Project Milestone 1'));
      expect(restored.tasks.first.priority, equals(TaskPriority.high));
      expect(restored.tasks.first.isCompleted, isFalse);
    });

    test('rejects backup with invalid app signature', () {
      final invalidJson = {
        'app': 'NotTaskora',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': 3,
        'lectures': [],
        'tasks': [],
      };

      expect(
        () => BackupPayload.fromJson(invalidJson),
        throwsA(isA<BackupValidationException>().having((e) => e.message, 'message', contains('signature'))),
      );
    });

    test('rejects backup with unsupported future version', () {
      final invalidJson = {
        'app': 'Taskora',
        'version': 99,
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': 3,
        'lectures': [],
        'tasks': [],
      };

      expect(
        () => BackupPayload.fromJson(invalidJson),
        throwsA(isA<BackupValidationException>().having((e) => e.message, 'message', contains('version'))),
      );
    });

    test('rejects backup with malformed lectures or tasks', () {
      final invalidLectureJson = {
        'app': 'Taskora',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': 3,
        'lectures': [
          {'courseName': '', 'dayOfWeek': 0, 'startTime': '09:00', 'endTime': '10:00'},
        ],
        'tasks': [],
      };

      expect(
        () => BackupPayload.fromJson(invalidLectureJson),
        throwsA(isA<BackupValidationException>().having((e) => e.message, 'message', contains('courseName'))),
      );

      final invalidTimeJson = {
        'app': 'Taskora',
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': 3,
        'lectures': [
          {'courseName': 'Math', 'dayOfWeek': 0, 'startTime': 'invalid', 'endTime': '10:00'},
        ],
        'tasks': [],
      };

      expect(
        () => BackupPayload.fromJson(invalidTimeJson),
        throwsA(isA<BackupValidationException>().having((e) => e.message, 'message', contains('time format'))),
      );
    });
  });

  group('BackupService End-to-End Database Round-trip Tests', () {
    test('exports, clears, and completely restores all timetable and task records', () async {
      // 1. Seed database
      await database.into(database.lectures).insert(
            LecturesCompanion.insert(
              courseName: 'Operating Systems',
              courseCode: const drift.Value('CS301'),
              room: const drift.Value('Lab 2'),
              instructor: const drift.Value('Dr. Jane'),
              dayOfWeek: 2,
              startTime: '11:00',
              endTime: '12:30',
              notes: const drift.Value('Bring USB drive'),
            ),
          );

      await database.into(database.lectures).insert(
            LecturesCompanion.insert(
              courseName: 'Linear Algebra',
              courseCode: const drift.Value('MATH201'),
              dayOfWeek: 3,
              startTime: '13:00',
              endTime: '14:30',
            ),
          );

      await database.into(database.tasks).insert(
            TasksCompanion.insert(
              title: 'Study Chapter 4',
              description: const drift.Value('Memory paging concepts'),
              courseName: const drift.Value('CS301'),
              priority: const drift.Value(2), // High
              isCompleted: const drift.Value(false),
            ),
          );

      await database.into(database.tasks).insert(
            TasksCompanion.insert(
              title: 'Matrix assignment',
              priority: const drift.Value(1), // Medium
              isCompleted: const drift.Value(true),
            ),
          );

      // Verify seed
      final initialLectures = await scheduleRepository.getAllLectures();
      final initialTasks = await taskRepository.getAllTasks();
      expect(initialLectures, hasLength(2));
      expect(initialTasks, hasLength(2));

      // 2. Create backup JSON string
      final backupJson = await backupService.createBackupJson();
      expect(backupJson, contains('"app": "Taskora"'));
      expect(backupJson, contains('Operating Systems'));
      expect(backupJson, contains('Study Chapter 4'));

      // 3. Clear database completely
      await database.delete(database.lectures).go();
      await database.delete(database.tasks).go();
      expect(await scheduleRepository.getAllLectures(), isEmpty);
      expect(await taskRepository.getAllTasks(), isEmpty);

      // 4. Parse & Restore
      final payload = backupService.parseAndValidateJson(backupJson);
      expect(payload.lectures, hasLength(2));
      expect(payload.tasks, hasLength(2));

      await backupService.restoreBackup(payload);

      // 5. Verify restored data
      final restoredLectures = await scheduleRepository.getAllLectures();
      final restoredTasks = await taskRepository.getAllTasks();

      expect(restoredLectures, hasLength(2));
      final osLecture = restoredLectures.firstWhere((l) => l.courseName == 'Operating Systems');
      expect(osLecture.courseCode, equals('CS301'));
      expect(osLecture.room, equals('Lab 2'));
      expect(osLecture.instructor, equals('Dr. Jane'));
      expect(osLecture.dayOfWeek, equals(2));
      expect(osLecture.startTime, equals('11:00'));
      expect(osLecture.endTime, equals('12:30'));
      expect(osLecture.notes, equals('Bring USB drive'));

      final mathLecture = restoredLectures.firstWhere((l) => l.courseName == 'Linear Algebra');
      expect(mathLecture.courseCode, equals('MATH201'));
      expect(mathLecture.dayOfWeek, equals(3));

      expect(restoredTasks, hasLength(2));
      final studyTask = restoredTasks.firstWhere((t) => t.title == 'Study Chapter 4');
      expect(studyTask.description, equals('Memory paging concepts'));
      expect(studyTask.priority, equals(TaskPriority.high));
      expect(studyTask.isCompleted, isFalse);

      final matrixTask = restoredTasks.firstWhere((t) => t.title == 'Matrix assignment');
      expect(matrixTask.isCompleted, isTrue);

      // 6. Verify reminder resync was called
      expect(mockReminderScheduler.resyncCallCount, equals(1));
    });
  });
}
