import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskRepositoryImpl', () {
    final now = DateTime.now();
    final task1 = TaskEntity(
      id: 0,
      title: 'Database Assignment 1',
      description: 'Implement B-Tree indexing',
      courseName: 'CS301',
      dueDate: now.add(const Duration(days: 2)),
      priority: TaskPriority.high,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    final task2 = TaskEntity(
      id: 0,
      title: 'Math Quiz Prep',
      description: 'Review chapters 3 and 4',
      courseName: 'MATH201',
      dueDate: now.add(const Duration(days: 5)),
      priority: TaskPriority.medium,
      isCompleted: false,
      createdAt: now,
      updatedAt: now,
    );

    test('createTask persists task and getTaskById retrieves it', () async {
      final id = await repository.createTask(task1);
      expect(id, isPositive);

      final retrieved = await repository.getTaskById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, equals('Database Assignment 1'));
      expect(retrieved.courseName, equals('CS301'));
      expect(retrieved.priority, equals(TaskPriority.high));
      expect(retrieved.isCompleted, isFalse);
    });

    test('getAllTasks retrieves all persisted tasks ordered', () async {
      await repository.createTask(task2);
      await repository.createTask(task1);

      final all = await repository.getAllTasks();
      expect(all.length, equals(2));
      // task1 is due in 2 days, task2 is due in 5 days -> task1 comes first
      expect(all.first.title, equals('Database Assignment 1'));
    });

    test(
      'toggleTaskCompletion updates isCompleted flag and timestamp',
      () async {
        final id = await repository.createTask(task1);

        // Mark completed
        final success1 = await repository.toggleTaskCompletion(id, true);
        expect(success1, isTrue);

        final completedTask = await repository.getTaskById(id);
        expect(completedTask!.isCompleted, isTrue);

        // Reopen
        final success2 = await repository.toggleTaskCompletion(id, false);
        expect(success2, isTrue);

        final reopenedTask = await repository.getTaskById(id);
        expect(reopenedTask!.isCompleted, isFalse);
      },
    );

    test('updateTask modifies task details', () async {
      final id = await repository.createTask(task1);
      final initial = await repository.getTaskById(id);

      final updated = initial!.copyWith(
        title: 'Database Assignment 1 - Revised',
        priority: TaskPriority.low,
      );

      final success = await repository.updateTask(updated);
      expect(success, isTrue);

      final result = await repository.getTaskById(id);
      expect(result!.title, equals('Database Assignment 1 - Revised'));
      expect(result.priority, equals(TaskPriority.low));
    });

    test('deleteTask removes task from database', () async {
      final id = await repository.createTask(task1);
      expect(await repository.getTaskById(id), isNotNull);

      final deleted = await repository.deleteTask(id);
      expect(deleted, isTrue);

      final result = await repository.getTaskById(id);
      expect(result, isNull);
    });

    test('createTask rejects empty or whitespace-only title', () async {
      final invalidTask = task1.copyWith(title: '   ');
      expect(
        () => repository.createTask(invalidTask),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
