class RemindersState {
  final bool lectureRemindersEnabled;
  final bool taskRemindersEnabled;
  final bool hasNotificationPermission;
  final bool isLoading;
  final String? errorMessage;

  const RemindersState({
    this.lectureRemindersEnabled = true,
    this.taskRemindersEnabled = true,
    this.hasNotificationPermission = false,
    this.isLoading = false,
    this.errorMessage,
  });

  RemindersState copyWith({
    bool? lectureRemindersEnabled,
    bool? taskRemindersEnabled,
    bool? hasNotificationPermission,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RemindersState(
      lectureRemindersEnabled:
          lectureRemindersEnabled ?? this.lectureRemindersEnabled,
      taskRemindersEnabled: taskRemindersEnabled ?? this.taskRemindersEnabled,
      hasNotificationPermission:
          hasNotificationPermission ?? this.hasNotificationPermission,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
