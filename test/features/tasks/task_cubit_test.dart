import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_state.dart';

void main() {
  late AppDatabase db;
  late TaskRepository repository;
  late TaskCubit cubit;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = TaskRepositoryImpl(db);
    cubit = TaskCubit(repository);
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  group('TaskCubit', () {
    test('initial state is loading, then emits empty list', () async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.allTasks, isEmpty);
      expect(cubit.state.totalPendingCount, equals(0));
      expect(cubit.state.totalCompletedCount, equals(0));
      expect(cubit.state.totalOverdueCount, equals(0));
    });

    test('createTask adds a task and reactively updates state', () async {
      final success = await cubit.createTask(
        title: 'Complete Lab Report',
        courseName: 'PHY101',
        dueDate: DateTime.now().add(const Duration(days: 3)),
        priority: TaskPriority.high,
      );

      expect(success, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.allTasks.length, equals(1));
      expect(cubit.state.allTasks.first.title, equals('Complete Lab Report'));
      expect(cubit.state.totalPendingCount, equals(1));
      expect(cubit.state.totalCompletedCount, equals(0));
    });

    test('toggleTaskCompletion toggles status and updates counts', () async {
      await cubit.createTask(title: 'Read Chapter 4');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final taskId = cubit.state.allTasks.first.id;
      expect(cubit.state.totalPendingCount, equals(1));

      // Mark completed
      await cubit.toggleTaskCompletion(taskId, true);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.totalPendingCount, equals(0));
      expect(cubit.state.totalCompletedCount, equals(1));

      // Reopen
      await cubit.toggleTaskCompletion(taskId, false);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.totalPendingCount, equals(1));
      expect(cubit.state.totalCompletedCount, equals(0));
    });

    test(
      'filtering correctly splits pending, completed, and overdue',
      () async {
        final now = DateTime.now();

        // Pending future task
        await cubit.createTask(
          title: 'Future Task',
          dueDate: now.add(const Duration(days: 3)),
        );

        // Overdue task
        await cubit.createTask(
          title: 'Overdue Task',
          dueDate: now.subtract(const Duration(days: 2)),
        );

        // Completed task
        await cubit.createTask(title: 'Done Task');
        await Future<void>.delayed(const Duration(milliseconds: 50));

        final doneTaskId = cubit.state.allTasks
            .firstWhere((t) => t.title == 'Done Task')
            .id;
        await cubit.toggleTaskCompletion(doneTaskId, true);
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Verify counts
        expect(cubit.state.totalPendingCount, equals(2));
        expect(cubit.state.totalCompletedCount, equals(1));
        expect(cubit.state.totalOverdueCount, equals(1));

        // Filter: Pending
        cubit.setFilter(TaskFilter.pending);
        expect(cubit.state.filteredTasks.length, equals(2));

        // Filter: Completed
        cubit.setFilter(TaskFilter.completed);
        expect(cubit.state.filteredTasks.length, equals(1));
        expect(cubit.state.filteredTasks.first.title, equals('Done Task'));

        // Filter: Overdue
        cubit.setFilter(TaskFilter.overdue);
        expect(cubit.state.filteredTasks.length, equals(1));
        expect(cubit.state.filteredTasks.first.title, equals('Overdue Task'));
      },
    );

    test('search query filters tasks by title or course name', () async {
      await cubit.createTask(title: 'Algorithms Homework', courseName: 'CS301');
      await cubit.createTask(title: 'History Essay', courseName: 'HIST101');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      cubit.setSearchQuery('algo');
      expect(cubit.state.filteredTasks.length, equals(1));
      expect(
        cubit.state.filteredTasks.first.title,
        equals('Algorithms Homework'),
      );

      cubit.setSearchQuery('HIST');
      expect(cubit.state.filteredTasks.length, equals(1));
      expect(cubit.state.filteredTasks.first.title, equals('History Essay'));

      cubit.setSearchQuery('');
      expect(cubit.state.filteredTasks.length, equals(2));
    });

    test('deleteTask removes task from repository and updates state', () async {
      await cubit.createTask(title: 'Task to Delete');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final taskId = cubit.state.allTasks.first.id;
      await cubit.deleteTask(taskId);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.allTasks, isEmpty);
    });

    test('createTask rejects empty title with error message', () async {
      final success = await cubit.createTask(title: '   ');
      expect(success, isFalse);
      expect(cubit.state.errorMessage, equals('Task title cannot be empty'));
    });
  });
}
