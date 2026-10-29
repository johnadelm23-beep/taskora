/// Defines the architecture boundary for Phase 2 local SQLite persistence using Drift.
///
/// Boundaries:
/// 1. UI Widgets & Presentation: Never access Drift database classes directly.
/// 2. Cubits: Rely strictly on domain repository interfaces.
/// 3. Repositories: Implement domain interfaces using Drift DAOs / Tables.
/// 4. Drift SQLite Database: Encapsulates schema definitions, migrations, and local queries.
library;

/// Base contract for lifecycle initialization of the offline local database.
abstract class LocalDatabaseClient {
  Future<void> initialize();
  Future<void> close();
}

/// Boundary contract for schedule & lecture management in SQLite.
abstract class ScheduleRepositoryBoundary {
  // Methods to be implemented with Drift in Phase 2:
  // Stream<List<LectureEntity>> watchTodayLectures();
  // Future<List<LectureEntity>> getWeeklyTimetable();
  // Future<void> saveLecture(LectureEntity lecture);
  // Future<void> deleteLecture(int id);
}

/// Boundary contract for task & deadline management in SQLite.
abstract class TaskRepositoryBoundary {
  // Methods to be implemented with Drift in Phase 2:
  // Stream<List<TaskEntity>> watchUpcomingTasks();
  // Future<List<TaskEntity>> getAllTasks();
  // Future<void> saveTask(TaskEntity task);
  // Future<void> toggleTaskCompleted(int id, bool isCompleted);
  // Future<void> deleteTask(int id);
}
