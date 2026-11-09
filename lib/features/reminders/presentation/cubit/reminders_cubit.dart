import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  final NotificationService notificationService;
  final PreferencesService preferencesService;
  final ReminderScheduler reminderScheduler;

  RemindersCubit({
    required this.notificationService,
    required this.preferencesService,
    required this.reminderScheduler,
  }) : super(
         RemindersState(
           lectureRemindersEnabled: preferencesService
               .getLectureRemindersEnabled(),
           taskRemindersEnabled: preferencesService.getTaskRemindersEnabled(),
         ),
       ) {
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await notificationService.arePermissionsGranted();
    emit(state.copyWith(hasNotificationPermission: granted));
  }

  Future<void> requestPermissions() async {
    final granted = await notificationService.requestPermissions();
    emit(state.copyWith(hasNotificationPermission: granted));
    if (granted) {
      await reminderScheduler.resyncAllReminders();
    }
  }

  Future<void> toggleLectureReminders(bool enabled) async {
    await preferencesService.setLectureRemindersEnabled(enabled);
    emit(state.copyWith(lectureRemindersEnabled: enabled));

    if (enabled) {
      if (!state.hasNotificationPermission) {
        await requestPermissions();
      } else {
        await reminderScheduler.resyncAllReminders();
      }
    } else {
      await reminderScheduler.cancelAllLectureReminders();
    }
  }

  Future<void> toggleTaskReminders(bool enabled) async {
    await preferencesService.setTaskRemindersEnabled(enabled);
    emit(state.copyWith(taskRemindersEnabled: enabled));

    if (enabled) {
      if (!state.hasNotificationPermission) {
        await requestPermissions();
      } else {
        await reminderScheduler.resyncAllReminders();
      }
    } else {
      await reminderScheduler.cancelAllTaskReminders();
    }
  }

  Future<void> resyncAllReminders() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await reminderScheduler.resyncAllReminders();
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }
}
