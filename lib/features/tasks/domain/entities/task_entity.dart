enum TaskPriority {
  low(0),
  medium(1),
  high(2);

  final int value;
  const TaskPriority(this.value);

  static TaskPriority fromValue(int value) {
    switch (value) {
      case 2:
        return TaskPriority.high;
      case 0:
        return TaskPriority.low;
      case 1:
      default:
        return TaskPriority.medium;
    }
  }
}

class TaskEntity {
  final int id;
  final String title;
  final String? description;
  final String? courseName;
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    this.courseName,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// A task is overdue if it is not completed, has a due date, and the due date is in the past.
  bool get isOverdue {
    if (isCompleted || dueDate == null) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  /// Checks if the task is due today in the device's local calendar day.
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final local = dueDate!.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  /// Checks if the task is due tomorrow in the device's local calendar day.
  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final local = dueDate!.toLocal();
    return local.year == tomorrow.year &&
        local.month == tomorrow.month &&
        local.day == tomorrow.day;
  }

  TaskEntity copyWith({
    int? id,
    String? title,
    String? description,
    String? courseName,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      courseName: courseName ?? this.courseName,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          courseName == other.courseName &&
          dueDate == other.dueDate &&
          priority == other.priority &&
          isCompleted == other.isCompleted &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      courseName.hashCode ^
      dueDate.hashCode ^
      priority.hashCode ^
      isCompleted.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
}
