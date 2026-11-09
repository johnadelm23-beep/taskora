import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_icons.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/notification/notification_service.dart';
import 'package:taskora/features/home/presentation/screens/home_screen.dart';
import 'package:taskora/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:taskora/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/presentation/screens/tasks_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  StreamSubscription<String>? _notificationTapSubscription;

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    TasksScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotificationTapListener();
  }

  void _initNotificationTapListener() {
    if (sl.isRegistered<NotificationService>()) {
      _notificationTapSubscription = sl<NotificationService>()
          .onNotificationTapped
          .listen((payload) {
            if (!mounted) return;
            if (payload.startsWith('schedule')) {
              context.read<NavigationCubit>().selectTab(1);
            } else if (payload.startsWith('tasks')) {
              context.read<NavigationCubit>().selectTab(2);
            }
          });
    }
  }

  @override
  void dispose() {
    _notificationTapSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<NavigationCubit, int>(
      builder: (context, currentIndex) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: _screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (index) {
              context.read<NavigationCubit>().selectTab(index);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(AppIcons.navHome, size: AppIcons.sizeDefault),
                selectedIcon: const Icon(
                  AppIcons.navHomeActive,
                  size: AppIcons.sizeDefault,
                ),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(
                  AppIcons.navSchedule,
                  size: AppIcons.sizeDefault,
                ),
                selectedIcon: const Icon(
                  AppIcons.navScheduleActive,
                  size: AppIcons.sizeDefault,
                ),
                label: l10n.navSchedule,
              ),
              NavigationDestination(
                icon: const Icon(AppIcons.navTasks, size: AppIcons.sizeDefault),
                selectedIcon: const Icon(
                  AppIcons.navTasksActive,
                  size: AppIcons.sizeDefault,
                ),
                label: l10n.navTasks,
              ),
              NavigationDestination(
                icon: const Icon(
                  AppIcons.navSettings,
                  size: AppIcons.sizeDefault,
                ),
                selectedIcon: const Icon(
                  AppIcons.navSettingsActive,
                  size: AppIcons.sizeDefault,
                ),
                label: l10n.navSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}
