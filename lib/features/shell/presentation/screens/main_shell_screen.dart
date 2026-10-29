import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/features/home/presentation/screens/home_screen.dart';
import 'package:taskora/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:taskora/features/settings/presentation/screens/settings_screen.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/presentation/screens/tasks_screen.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    ScheduleScreen(),
    TasksScreen(),
    SettingsScreen(),
  ];

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
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: l10n.navHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month_rounded),
                label: l10n.navSchedule,
              ),
              NavigationDestination(
                icon: const Icon(Icons.checklist_outlined),
                selectedIcon: const Icon(Icons.checklist_rounded),
                label: l10n.navTasks,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: l10n.navSettings,
              ),
            ],
          ),
        );
      },
    );
  }
}
