import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/router/app_router.dart';
import 'package:taskora/app/theme/app_theme.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';

class TaskoraApp extends StatelessWidget {
  const TaskoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => sl<ThemeCubit>()),
        BlocProvider<LocaleCubit>(create: (_) => sl<LocaleCubit>()),
        BlocProvider<NavigationCubit>(create: (_) => sl<NavigationCubit>()),
        BlocProvider<ScheduleCubit>(create: (_) => sl<ScheduleCubit>()),
        BlocProvider<TaskCubit>(create: (_) => sl<TaskCubit>()),
        BlocProvider<ImportScheduleCubit>(
          create: (_) => sl<ImportScheduleCubit>(),
        ),
      ],
      child: ScreenUtilInit(
        designSize: AppConstants.designSize,
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, _) {
          return BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return BlocBuilder<LocaleCubit, Locale?>(
                builder: (context, locale) {
                  return MaterialApp(
                    title: AppConstants.appName,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeMode,
                    locale: locale,
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates: const [
                      AppLocalizations.delegate,
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    onGenerateRoute: AppRouter.onGenerateRoute,
                    initialRoute: AppRouter.initialRoute,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
