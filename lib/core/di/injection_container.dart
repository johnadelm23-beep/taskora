import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/backup/backup_service.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/import_schedule/domain/services/csv_timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/reminders/domain/services/reminder_scheduler.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({
  AppDatabase? customDatabase,
  NotificationService? customNotificationService,
}) async {
  // 1. External & Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesServiceImpl(sl()),
  );

  final database = customDatabase ?? AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => database);

  final notificationService =
      customNotificationService ?? NotificationServiceImpl();
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  // 2. Repositories & Domain Services
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(sl()));

  sl.registerLazySingleton<CsvTimetableParser>(() => CsvTimetableParser());

  sl.registerLazySingleton<ReminderScheduler>(
    () => ReminderSchedulerImpl(
      notificationService: sl(),
      preferencesService: sl(),
      scheduleRepository: sl(),
      taskRepository: sl(),
    ),
  );

  sl.registerLazySingleton<BackupService>(
    () => BackupServiceImpl(
      database: sl(),
      scheduleRepository: sl(),
      taskRepository: sl(),
      reminderScheduler: sl(),
    ),
  );

  // 3. Application State (Cubits)
  sl.registerFactory<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerFactory<LocaleCubit>(() => LocaleCubit(sl()));
  sl.registerFactory<NavigationCubit>(() => NavigationCubit());
  sl.registerFactory<RemindersCubit>(
    () => RemindersCubit(
      notificationService: sl(),
      preferencesService: sl(),
      reminderScheduler: sl(),
    ),
  );
  sl.registerFactory<ScheduleCubit>(() => ScheduleCubit(sl(), sl()));
  sl.registerFactory<TaskCubit>(() => TaskCubit(sl(), sl()));
  sl.registerFactory<ImportScheduleCubit>(
    () => ImportScheduleCubit(
      csvParser: sl(),
      scheduleRepository: sl(),
      reminderScheduler: sl(),
    ),
  );
}
