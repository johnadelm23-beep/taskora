import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:taskora/core/backup/backup_payload.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';

abstract class BackupService {
  /// Queries database and produces a formatted, versioned JSON backup string.
  Future<String> createBackupJson();

  /// Prompts user to save the backup JSON file locally via file picker.
  Future<String?> saveBackupToFile(
    String backupJson, {
    String? defaultFileName,
  });

  /// Prompts user to pick a backup .json file and strictly validates its schema and records.
  Future<BackupPayload?> pickAndValidateBackup();

  /// Validates a raw JSON string and returns a [BackupPayload], throwing [BackupValidationException] on failure.
  BackupPayload parseAndValidateJson(String jsonContent);

  /// Atomically restores all lectures and tasks into the database and resyncs system notifications.
  Future<void> restoreBackup(BackupPayload payload);
}

class BackupServiceImpl implements BackupService {
  final AppDatabase database;
  final ScheduleRepository scheduleRepository;
  final TaskRepository taskRepository;
  final ReminderScheduler reminderScheduler;

  BackupServiceImpl({
    required this.database,
    required this.scheduleRepository,
    required this.taskRepository,
    required this.reminderScheduler,
  });

  @override
  Future<String> createBackupJson() async {
    final lectures = await scheduleRepository.getAllLectures();
    final tasks = await taskRepository.getAllTasks();

    final payload = BackupPayload(
      exportedAt: DateTime.now(),
      schemaVersion: database.schemaVersion,
      lectures: lectures,
      tasks: tasks,
    );

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payload.toJson());
  }

  @override
  Future<String?> saveBackupToFile(
    String backupJson, {
    String? defaultFileName,
  }) async {
    try {
      final bytes = utf8.encode(backupJson);
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .split('.')
          .first;
      final fileName = defaultFileName ?? 'taskora_backup_$timestamp.json';

      final resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Taskora Backup',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (resultPath != null && resultPath.isNotEmpty) {
        final file = File(resultPath);
        if (!await file.exists() || (await file.length()) == 0) {
          await file.writeAsBytes(bytes, flush: true);
        }
      }

      return resultPath;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<BackupPayload?> pickAndValidateBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;
    String content;

    if (picked.bytes != null && picked.bytes!.isNotEmpty) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null && picked.path!.isNotEmpty) {
      final file = File(picked.path!);
      content = await file.readAsString();
    } else {
      throw const BackupValidationException(
        'Unable to read selected backup file content.',
      );
    }

    return parseAndValidateJson(content);
  }

  @override
  BackupPayload parseAndValidateJson(String jsonContent) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonContent);
    } catch (e) {
      throw BackupValidationException('Malformed JSON: ${e.toString()}');
    }

    if (decoded is! Map<String, dynamic> && decoded is! Map) {
      throw const BackupValidationException(
        'Root backup structure must be a JSON object.',
      );
    }

    return BackupPayload.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<void> restoreBackup(BackupPayload payload) async {
    final lectureCompanions = payload.lectures.map((l) {
      return LecturesCompanion(
        id: Value(l.id),
        courseName: Value(l.courseName),
        courseCode: Value(l.courseCode),
        room: Value(l.room),
        instructor: Value(l.instructor),
        dayOfWeek: Value(l.dayOfWeek),
        startTime: Value(l.startTime),
        endTime: Value(l.endTime),
        colorHex: Value(l.colorHex),
        notes: Value(l.notes),
        createdAt: Value(l.createdAt ?? DateTime.now()),
        updatedAt: Value(l.updatedAt ?? DateTime.now()),
      );
    }).toList();

    final taskCompanions = payload.tasks.map((t) {
      return TasksCompanion(
        id: Value(t.id),
        title: Value(t.title),
        description: Value(t.description),
        courseName: Value(t.courseName),
        dueDate: Value(t.dueDate),
        priority: Value(t.priority.value),
        isCompleted: Value(t.isCompleted),
        createdAt: Value(t.createdAt),
        updatedAt: Value(t.updatedAt),
      );
    }).toList();

    // 1. Atomic SQLite restore transaction
    await database.restoreBackup(
      restoredLectures: lectureCompanions,
      restoredTasks: taskCompanions,
    );

    // 2. Resync all alarms/notifications
    await reminderScheduler.resyncAllReminders();
  }
}
