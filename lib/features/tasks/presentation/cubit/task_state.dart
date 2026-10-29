import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

enum TaskFilter { all, pending, completed, overdue }

class TaskState {
  final bool isLoading;
  final bool isSaving;
  final List<TaskEntity> allTasks;
  final TaskFilter activeFilter;
  final String searchQuery;
  final String? errorMessage;

  const TaskState({
    this.isLoading = false,
    this.isSaving = false,
    this.allTasks = const [],
    this.activeFilter = TaskFilter.all,
    this.searchQuery = '',
    this.errorMessage,
  });

  /// Total count of pending (incomplete) tasks.
  int get totalPendingCount => allTasks.where((t) => !t.isCompleted).length;

  /// Total count of completed tasks.
  int get totalCompletedCount => allTasks.where((t) => t.isCompleted).length;

  /// Total count of overdue tasks.
  int get totalOverdueCount => allTasks.where((t) => t.isOverdue).length;

  /// Upcoming deadlines count (pending tasks due within the next 7 days, excluding overdue).
  int get upcomingDueCount {
    final now = DateTime.now();
    final sevenDaysAhead = now.add(const Duration(days: 7));
    return allTasks.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isAfter(now) && t.dueDate!.isBefore(sevenDaysAhead);
    }).length;
  }

  /// Filtered and sorted tasks according to activeFilter and searchQuery.
  List<TaskEntity> get filteredTasks {
    List<TaskEntity> result = allTasks;

    switch (activeFilter) {
      case TaskFilter.pending:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.overdue:
        result = result.where((t) => t.isOverdue).toList();
        break;
      case TaskFilter.all:
        break;
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      result = result.where((t) {
        final titleMatches = t.title.toLowerCase().contains(query);
        final descMatches =
            t.description?.toLowerCase().contains(query) ?? false;
        final courseMatches =
            t.courseName?.toLowerCase().contains(query) ?? false;
        return titleMatches || descMatches || courseMatches;
      }).toList();
    }

    return result;
  }

  /// Top upcoming pending tasks for Home screen preview (sorted nearest deadline first).
  List<TaskEntity> get upcomingPendingTasks {
    final pending = allTasks.where((t) => !t.isCompleted).toList();
    pending.sort((a, b) {
      // Overdue first
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;

      // Then nearest due date
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      }
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;

      // Then higher priority first
      return b.priority.value.compareTo(a.priority.value);
    });

    return pending.take(4).toList();
  }

  TaskState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<TaskEntity>? allTasks,
    TaskFilter? activeFilter,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      allTasks: allTasks ?? this.allTasks,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
