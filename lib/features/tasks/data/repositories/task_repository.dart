import 'package:drift/drift.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

abstract class TaskRepository {
  /// Watches all tasks in the database, ordered by completion status, due date, and priority.
  Stream<List<TaskEntity>> watchAllTasks();

  /// Retrieves all tasks once.
  Future<List<TaskEntity>> getAllTasks();

  /// Watches pending (incomplete) tasks.
  Stream<List<TaskEntity>> watchPendingTasks();

  /// Watches completed tasks.
  Stream<List<TaskEntity>> watchCompletedTasks();

  /// Retrieves a task by its unique ID.
  Future<TaskEntity?> getTaskById(int id);

  /// Inserts a new task and returns its auto-generated ID.
  Future<int> createTask(TaskEntity task);

  /// Updates an existing task's fields.
  Future<bool> updateTask(TaskEntity task);

  /// Toggles completion status of a task.
  Future<bool> toggleTaskCompletion(int id, bool isCompleted);

  /// Deletes a task by its unique ID.
  Future<bool> deleteTask(int id);
}

class TaskRepositoryImpl implements TaskRepository {
  final AppDatabase _db;

  TaskRepositoryImpl(this._db);

  @override
  Stream<List<TaskEntity>> watchAllTasks() {
    return (_db.select(_db.tasks)..orderBy([
          (t) =>
              OrderingTerm(expression: t.isCompleted, mode: OrderingMode.asc),
          (t) => OrderingTerm(
            expression: t.dueDate,
            mode: OrderingMode.asc,
            nulls: NullsOrder.last,
          ),
          (t) => OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
        ]))
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<List<TaskEntity>> getAllTasks() async {
    final rows =
        await (_db.select(_db.tasks)..orderBy([
              (t) => OrderingTerm(
                expression: t.isCompleted,
                mode: OrderingMode.asc,
              ),
              (t) => OrderingTerm(
                expression: t.dueDate,
                mode: OrderingMode.asc,
                nulls: NullsOrder.last,
              ),
              (t) =>
                  OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
            ]))
            .get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Stream<List<TaskEntity>> watchPendingTasks() {
    return (_db.select(_db.tasks)
          ..where((t) => t.isCompleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.dueDate,
              mode: OrderingMode.asc,
              nulls: NullsOrder.last,
            ),
            (t) =>
                OrderingTerm(expression: t.priority, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Stream<List<TaskEntity>> watchCompletedTasks() {
    return (_db.select(_db.tasks)
          ..where((t) => t.isCompleted.equals(true))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch()
        .map((rows) => rows.map(_mapToEntity).toList());
  }

  @override
  Future<TaskEntity?> getTaskById(int id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<int> createTask(TaskEntity task) async {
    final trimmedTitle = task.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    final now = DateTime.now();
    final companion = TasksCompanion.insert(
      title: trimmedTitle,
      description: Value(task.description?.trim()),
      courseName: Value(
        task.courseName?.trim().isNotEmpty == true
            ? task.courseName!.trim()
            : null,
      ),
      dueDate: Value(task.dueDate),
      priority: Value(task.priority.value),
      isCompleted: Value(task.isCompleted),
      createdAt: Value(task.createdAt),
      updatedAt: Value(now),
    );

    return await _db.into(_db.tasks).insert(companion);
  }

  @override
  Future<bool> updateTask(TaskEntity task) async {
    final trimmedTitle = task.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Task title cannot be empty');
    }

    final now = DateTime.now();
    final statement = _db.update(_db.tasks)..where((t) => t.id.equals(task.id));
    final count = await statement.write(
      TasksCompanion(
        title: Value(trimmedTitle),
        description: Value(task.description?.trim()),
        courseName: Value(
          task.courseName?.trim().isNotEmpty == true
              ? task.courseName!.trim()
              : null,
        ),
        dueDate: Value(task.dueDate),
        priority: Value(task.priority.value),
        isCompleted: Value(task.isCompleted),
        updatedAt: Value(now),
      ),
    );

    return count > 0;
  }

  @override
  Future<bool> toggleTaskCompletion(int id, bool isCompleted) async {
    final now = DateTime.now();
    final statement = _db.update(_db.tasks)..where((t) => t.id.equals(id));
    final count = await statement.write(
      TasksCompanion(isCompleted: Value(isCompleted), updatedAt: Value(now)),
    );
    return count > 0;
  }

  @override
  Future<bool> deleteTask(int id) async {
    final count = await (_db.delete(
      _db.tasks,
    )..where((t) => t.id.equals(id))).go();
    return count > 0;
  }

  TaskEntity _mapToEntity(Task row) {
    return TaskEntity(
      id: row.id,
      title: row.title,
      description: row.description,
      courseName: row.courseName,
      dueDate: row.dueDate?.toLocal(),
      priority: TaskPriority.fromValue(row.priority),
      isCompleted: row.isCompleted,
      createdAt: row.createdAt.toLocal(),
      updatedAt: row.updatedAt.toLocal(),
    );
  }
}
