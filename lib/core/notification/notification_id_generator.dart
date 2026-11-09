/// Deterministic Notification ID generation to guarantee collision-free
/// scheduling between lectures and tasks within 32-bit signed integer space.
class NotificationIdGenerator {
  NotificationIdGenerator._();

  static const int lectureBaseId = 1000000;
  static const int taskBaseId = 2000000;

  /// Generates a unique notification ID for a lecture.
  static int forLecture(int lectureId) {
    return lectureBaseId + lectureId;
  }

  /// Generates a unique notification ID for a task.
  static int forTask(int taskId) {
    return taskBaseId + taskId;
  }

  /// Determines whether a notification ID belongs to a lecture.
  static bool isLecture(int id) {
    return id >= lectureBaseId && id < taskBaseId;
  }

  /// Determines whether a notification ID belongs to a task.
  static bool isTask(int id) {
    return id >= taskBaseId;
  }
}
