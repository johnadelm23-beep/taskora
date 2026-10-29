import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/database/app_database.dart';
import 'package:taskora/core/storage/preferences_service.dart';
import 'package:taskora/features/import_schedule/data/services/on_device_text_extractor_impl.dart';
import 'package:taskora/features/import_schedule/domain/services/text_extractor_service.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_parser.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/schedule/data/repositories/schedule_repository.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/data/repositories/task_repository.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies({AppDatabase? customDatabase}) async {
  // 1. External & Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  sl.registerLazySingleton<PreferencesService>(
    () => PreferencesServiceImpl(sl()),
  );

  final database = customDatabase ?? AppDatabase();
  sl.registerLazySingleton<AppDatabase>(() => database);

  // 2. Repositories & Domain Services
  sl.registerLazySingleton<ScheduleRepository>(
    () => ScheduleRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<TaskRepository>(() => TaskRepositoryImpl(sl()));

  sl.registerLazySingleton<TextExtractorService>(
    () => OnDeviceTextExtractorImpl(),
  );
  sl.registerLazySingleton<TimetableParser>(() => TimetableParser());

  // 3. Application State (Cubits)
  sl.registerFactory<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerFactory<LocaleCubit>(() => LocaleCubit(sl()));
  sl.registerFactory<NavigationCubit>(() => NavigationCubit());
  sl.registerFactory<ScheduleCubit>(() => ScheduleCubit(sl()));
  sl.registerFactory<TaskCubit>(() => TaskCubit(sl()));
  sl.registerFactory<ImportScheduleCubit>(
    () => ImportScheduleCubit(
      textExtractor: sl(),
      parser: sl(),
      scheduleRepository: sl(),
    ),
  );
}
