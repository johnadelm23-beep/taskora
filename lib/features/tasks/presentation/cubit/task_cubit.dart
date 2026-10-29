import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_state.dart';

class TaskCubit extends Cubit<TaskState> {
  final TaskRepository _repository;
  StreamSubscription<List<TaskEntity>>? _tasksSubscription;

  TaskCubit(this._repository) : super(const TaskState(isLoading: true)) {
    _init();
  }

  void _init() {
    _tasksSubscription = _repository.watchAllTasks().listen(
      (tasks) {
        emit(
          state.copyWith(allTasks: tasks, isLoading: false, clearError: true),
        );
      },
      onError: (error) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to load tasks: $error',
          ),
        );
      },
    );
  }

  void setFilter(TaskFilter filter) {
    emit(state.copyWith(activeFilter: filter));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<bool> createTask({
    required String title,
    String? description,
    String? courseName,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(errorMessage: 'Task title cannot be empty'));
      return false;
    }

    if (state.isSaving) return false;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final now = DateTime.now();
      final task = TaskEntity(
        id: 0,
        title: trimmed,
        description: description?.trim().isNotEmpty == true
            ? description!.trim()
            : null,
        courseName: courseName?.trim().isNotEmpty == true
            ? courseName!.trim()
            : null,
        dueDate: dueDate,
        priority: priority,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.createTask(task);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to create task: $e',
        ),
      );
      return false;
    }
  }

  Future<bool> updateTask(TaskEntity task) async {
    final trimmed = task.title.trim();
    if (trimmed.isEmpty) {
      emit(state.copyWith(errorMessage: 'Task title cannot be empty'));
      return false;
    }

    if (state.isSaving) return false;

    emit(state.copyWith(isSaving: true, clearError: true));

    try {
      final updated = task.copyWith(
        title: trimmed,
        description: task.description?.trim().isNotEmpty == true
            ? task.description!.trim()
            : null,
        courseName: task.courseName?.trim().isNotEmpty == true
            ? task.courseName!.trim()
            : null,
        updatedAt: DateTime.now(),
      );

      final success = await _repository.updateTask(updated);
      emit(state.copyWith(isSaving: false));
      return success;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to update task: $e',
        ),
      );
      return false;
    }
  }

  Future<void> toggleTaskCompletion(int id, bool isCompleted) async {
    try {
      await _repository.toggleTaskCompletion(id, isCompleted);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to update task status: $e'));
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await _repository.deleteTask(id);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to delete task: $e'));
    }
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
