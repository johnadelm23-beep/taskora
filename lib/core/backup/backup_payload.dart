import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

class BackupValidationException implements Exception {
  final String message;
  const BackupValidationException(this.message);

  @override
  String toString() => 'BackupValidationException: $message';
}

/// Represents the complete, validated payload of a Taskora local database backup.
class BackupPayload {
  static const String appIdentifier = 'Taskora';
  static const int currentVersion = 1;

  final int version;
  final DateTime exportedAt;
  final int schemaVersion;
  final List<LectureEntity> lectures;
  final List<TaskEntity> tasks;

  const BackupPayload({
    this.version = currentVersion,
    required this.exportedAt,
    required this.schemaVersion,
    required this.lectures,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'app': appIdentifier,
      'version': version,
      'exportedAt': exportedAt.toUtc().toIso8601String(),
      'schemaVersion': schemaVersion,
      'lectures': lectures.map((l) {
        return {
          'id': l.id,
          'courseName': l.courseName,
          'courseCode': l.courseCode,
          'room': l.room,
          'instructor': l.instructor,
          'dayOfWeek': l.dayOfWeek,
          'startTime': l.startTime,
          'endTime': l.endTime,
          'colorHex': l.colorHex,
          'notes': l.notes,
          'createdAt': l.createdAt?.toUtc().toIso8601String(),
          'updatedAt': l.updatedAt?.toUtc().toIso8601String(),
        };
      }).toList(),
      'tasks': tasks.map((t) {
        return {
          'id': t.id,
          'title': t.title,
          'description': t.description,
          'courseName': t.courseName,
          'dueDate': t.dueDate?.toUtc().toIso8601String(),
          'priority': t.priority.value,
          'isCompleted': t.isCompleted,
          'createdAt': t.createdAt.toUtc().toIso8601String(),
          'updatedAt': t.updatedAt.toUtc().toIso8601String(),
        };
      }).toList(),
    };
  }

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    if (json['app'] != appIdentifier) {
      throw const BackupValidationException(
        'Invalid backup file: missing or incorrect application signature.',
      );
    }

    final version = json['version'];
    if (version == null || version is! int || version > currentVersion) {
      throw BackupValidationException(
        'Unsupported backup format version: $version (expected <= $currentVersion).',
      );
    }

    final exportedAtStr = json['exportedAt'];
    if (exportedAtStr == null || exportedAtStr is! String) {
      throw const BackupValidationException(
        'Missing or invalid export timestamp.',
      );
    }
    final exportedAt = DateTime.tryParse(exportedAtStr);
    if (exportedAt == null) {
      throw const BackupValidationException(
        'Malformed export timestamp in backup file.',
      );
    }

    final schemaVersion = json['schemaVersion'];
    if (schemaVersion == null || schemaVersion is! int) {
      throw const BackupValidationException(
        'Missing or invalid schemaVersion in backup.',
      );
    }

    final rawLectures = json['lectures'];
    if (rawLectures == null || rawLectures is! List) {
      throw const BackupValidationException(
        'Malformed backup: "lectures" must be a list.',
      );
    }

    final rawTasks = json['tasks'];
    if (rawTasks == null || rawTasks is! List) {
      throw const BackupValidationException(
        'Malformed backup: "tasks" must be a list.',
      );
    }

    final lectures = <LectureEntity>[];
    for (int i = 0; i < rawLectures.length; i++) {
      final item = rawLectures[i];
      if (item is! Map<String, dynamic> && item is! Map) {
        throw BackupValidationException('Invalid lecture item at index $i.');
      }
      final map = Map<String, dynamic>.from(item as Map);
      final courseName = (map['courseName'] as String?)?.trim() ?? '';
      if (courseName.isEmpty) {
        throw BackupValidationException(
          'Lecture at index $i is missing required courseName.',
        );
      }

      final dayOfWeek = map['dayOfWeek'];
      if (dayOfWeek is! int || dayOfWeek < 0 || dayOfWeek > 6) {
        throw BackupValidationException(
          'Lecture at index $i has invalid dayOfWeek: $dayOfWeek.',
        );
      }

      final startTime = (map['startTime'] as String?)?.trim() ?? '';
      final endTime = (map['endTime'] as String?)?.trim() ?? '';
      if (!_isValidTime(startTime) || !_isValidTime(endTime)) {
        throw BackupValidationException(
          'Lecture at index $i has invalid time format ($startTime - $endTime).',
        );
      }

      lectures.add(
        LectureEntity(
          id: (map['id'] as int?) ?? 0,
          courseName: courseName,
          courseCode: (map['courseCode'] as String?)?.trim() ?? '',
          room: (map['room'] as String?)?.trim() ?? '',
          instructor: (map['instructor'] as String?)?.trim() ?? '',
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          endTime: endTime,
          colorHex: map['colorHex'] as int?,
          notes: map['notes'] as String?,
          createdAt: map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'] as String)
              : null,
          updatedAt: map['updatedAt'] != null
              ? DateTime.tryParse(map['updatedAt'] as String)
              : null,
        ),
      );
    }

    final tasks = <TaskEntity>[];
    for (int i = 0; i < rawTasks.length; i++) {
      final item = rawTasks[i];
      if (item is! Map<String, dynamic> && item is! Map) {
        throw BackupValidationException('Invalid task item at index $i.');
      }
      final map = Map<String, dynamic>.from(item as Map);
      final title = (map['title'] as String?)?.trim() ?? '';
      if (title.isEmpty) {
        throw BackupValidationException(
          'Task at index $i is missing required title.',
        );
      }

      final priorityVal = map['priority'];
      final priority = priorityVal is int
          ? TaskPriority.fromValue(priorityVal)
          : TaskPriority.medium;

      final isCompleted = (map['isCompleted'] as bool?) ?? false;
      final createdAt = map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now())
          : DateTime.now();
      final updatedAt = map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now();

      tasks.add(
        TaskEntity(
          id: (map['id'] as int?) ?? 0,
          title: title,
          description: map['description'] as String?,
          courseName: map['courseName'] as String?,
          dueDate: map['dueDate'] != null
              ? DateTime.tryParse(map['dueDate'] as String)
              : null,
          priority: priority,
          isCompleted: isCompleted,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }

    return BackupPayload(
      version: version,
      exportedAt: exportedAt,
      schemaVersion: schemaVersion,
      lectures: lectures,
      tasks: tasks,
    );
  }

  static bool _isValidTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return false;
    return h >= 0 && h <= 23 && m >= 0 && m <= 59;
  }
}
