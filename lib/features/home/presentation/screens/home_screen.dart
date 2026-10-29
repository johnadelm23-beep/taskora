import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/empty_state_card.dart';
import 'package:taskora/core/widgets/section_header.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/import_source_sheet.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:taskora/features/schedule/presentation/widgets/lecture_card.dart';
import 'package:taskora/features/schedule/presentation/widgets/lecture_form_sheet.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_state.dart';
import 'package:taskora/features/tasks/presentation/widgets/task_card.dart';
import 'package:taskora/features/tasks/presentation/widgets/task_form_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final todayDayOfWeek = now.weekday % 7;

    final greeting = _getGreeting(l10n, now.hour);
    final formattedDate = _formatDate(l10n, now);

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<ScheduleCubit, ScheduleState>(
          builder: (context, scheduleState) {
            return BlocBuilder<TaskCubit, TaskState>(
              builder: (context, taskState) {
                final todayLectures = scheduleState.allLectures
                    .where((l) => l.dayOfWeek == todayDayOfWeek)
                    .toList();
                final nextLecture = scheduleState.nextLecture;
                final upcomingTasks = taskState.upcomingPendingTasks;

                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.space16,
                    vertical: AppConstants.space12,
                  ),
                  children: [
                    // A. Header
                    _buildHeader(context, theme, l10n, greeting, formattedDate),
                    const SizedBox(height: AppConstants.space16),

                    // B. Today's Overview (KPIs with real database values)
                    _buildOverviewRow(
                      context,
                      theme,
                      l10n,
                      todayLecturesCount: todayLectures.length,
                      pendingTasksCount: taskState.totalPendingCount,
                      upcomingDeadlinesCount: taskState.upcomingDueCount,
                    ),
                    const SizedBox(height: AppConstants.space20),

                    // C. Next Lecture Spotlight Card
                    _buildNextLectureCard(context, theme, l10n, nextLecture),
                    const SizedBox(height: AppConstants.space20),

                    // D. Quick Actions Row
                    _buildQuickActions(context, theme, l10n, todayDayOfWeek),
                    const SizedBox(height: AppConstants.space20),

                    // E. Today's Schedule Preview
                    _buildSchedulePreview(
                      context,
                      theme,
                      l10n,
                      todayLectures,
                      todayDayOfWeek,
                    ),
                    const SizedBox(height: AppConstants.space20),

                    // F. Tasks Preview
                    _buildTasksPreview(context, theme, l10n, upcomingTasks),
                    const SizedBox(height: AppConstants.space20),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    String greeting,
    String formattedDate,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppConstants.space4),
              Text(
                formattedDate,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {
            context.read<NavigationCubit>().selectTab(3);
          },
          icon: const Icon(Icons.settings_outlined, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          tooltip: l10n.navSettings,
        ),
      ],
    );
  }

  Widget _buildOverviewRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n, {
    required int todayLecturesCount,
    required int pendingTasksCount,
    required int upcomingDeadlinesCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context,
            theme,
            count: todayLecturesCount.toString(),
            label: l10n.overviewLectures,
            icon: Icons.menu_book_rounded,
            color: AppColors.primary,
            onTap: () => context.read<NavigationCubit>().selectTab(1),
          ),
        ),
        const SizedBox(width: AppConstants.space12),
        Expanded(
          child: _buildKpiCard(
            context,
            theme,
            count: pendingTasksCount.toString(),
            label: l10n.overviewTasks,
            icon: Icons.assignment_outlined,
            color: AppColors.secondary,
            onTap: () => context.read<NavigationCubit>().selectTab(2),
          ),
        ),
        const SizedBox(width: AppConstants.space12),
        Expanded(
          child: _buildKpiCard(
            context,
            theme,
            count: upcomingDeadlinesCount.toString(),
            label: l10n.overviewDeadlines,
            icon: Icons.access_time_rounded,
            color: AppColors.tertiary,
            onTap: () => context.read<NavigationCubit>().selectTab(2),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    ThemeData theme, {
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildNextLectureCard(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    LectureEntity? nextLecture,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.nextLectureTitle,
          actionLabel: l10n.viewWeeklySchedule,
          onActionTap: () => context.read<NavigationCubit>().selectTab(1),
        ),
        if (nextLecture != null)
          LectureCard(lecture: nextLecture)
        else
          AppCard(
            padding: const EdgeInsets.all(AppConstants.space16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.space12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppConstants.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.noUpcomingLecture,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        l10n.noUpcomingLectureDesc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    int todayDayIndex,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.quickActions),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                context,
                theme,
                label: l10n.quickActionAddTask,
                icon: Icons.add_task_rounded,
                color: AppColors.primary,
                onTap: () => TaskFormSheet.show(context),
              ),
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: _buildQuickActionItem(
                context,
                theme,
                label: l10n.quickActionAddLecture,
                icon: Icons.add_circle_outline_rounded,
                color: AppColors.secondary,
                onTap: () => LectureFormSheet.show(
                  context,
                  initialDayIndex: todayDayIndex,
                ),
              ),
            ),
            const SizedBox(width: AppConstants.space12),
            Expanded(
              child: _buildQuickActionItem(
                context,
                theme,
                label: l10n.quickActionImport,
                icon: Icons.document_scanner_outlined,
                color: AppColors.tertiary,
                onTap: () => _showImportSheet(context, l10n),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space8,
        vertical: AppConstants.space12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.space8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppConstants.space8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulePreview(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    List<LectureEntity> todayLectures,
    int todayDayIndex,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.todaysSchedule,
          actionLabel: l10n.viewAll,
          onActionTap: () => context.read<NavigationCubit>().selectTab(1),
        ),
        if (todayLectures.isEmpty)
          EmptyStateCard(
            icon: Icons.calendar_today_rounded,
            title: l10n.noLecturesToday,
            message: l10n.emptyScheduleMsg,
            action: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppButton(
                  text: l10n.addLecture,
                  onPressed: () => LectureFormSheet.show(
                    context,
                    initialDayIndex: todayDayIndex,
                  ),
                ),
                const SizedBox(width: AppConstants.space8),
                AppButton(
                  text: l10n.importSchedule,
                  isOutlined: true,
                  onPressed: () => _showImportSheet(context, l10n),
                ),
              ],
            ),
          )
        else
          Column(
            children: todayLectures.map((lecture) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.space12),
                child: LectureCard(lecture: lecture),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildTasksPreview(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
    List<TaskEntity> upcomingTasks,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.tasksPreviewTitle,
          actionLabel: l10n.viewAll,
          onActionTap: () => context.read<NavigationCubit>().selectTab(2),
        ),
        if (upcomingTasks.isEmpty)
          EmptyStateCard(
            icon: Icons.checklist_rounded,
            title: l10n.allCaughtUp,
            message: l10n.emptyTasksMsg,
            action: AppButton(
              text: l10n.addTask,
              onPressed: () => TaskFormSheet.show(context),
            ),
          )
        else
          Column(
            children: upcomingTasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.space12),
                child: TaskCard(
                  task: task,
                  onToggleCompletion: (completed) {
                    context.read<TaskCubit>().toggleTaskCompletion(
                      task.id,
                      completed,
                    );
                  },
                  onEdit: () => TaskFormSheet.show(context, taskToEdit: task),
                  onTap: () => context.read<NavigationCubit>().selectTab(2),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  String _getGreeting(AppLocalizations l10n, int hour) {
    if (hour < 12) {
      return l10n.greetingMorning;
    } else if (hour < 17) {
      return l10n.greetingAfternoon;
    } else {
      return l10n.greetingEvening;
    }
  }

  String _formatDate(AppLocalizations l10n, DateTime date) {
    try {
      final localeCode = l10n.locale.languageCode;
      final weekday = DateFormat.EEEE(localeCode).format(date);
      final monthDay = DateFormat.yMMMMd(localeCode).format(date);
      return '$weekday, $monthDay';
    } catch (_) {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showImportSheet(BuildContext context, AppLocalizations l10n) {
    ImportSourceSheet.show(context);
  }
}
