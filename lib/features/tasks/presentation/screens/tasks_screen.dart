import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/empty_state_card.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_state.dart';
import 'package:taskora/features/tasks/presentation/widgets/task_card.dart';
import 'package:taskora/features/tasks/presentation/widgets/task_form_sheet.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final filterOptions = [
          {'filter': TaskFilter.all, 'label': l10n.filterAll},
          {'filter': TaskFilter.pending, 'label': l10n.filterPending},
          {'filter': TaskFilter.completed, 'label': l10n.filterCompleted},
          {'filter': TaskFilter.overdue, 'label': l10n.filterOverdue},
        ];

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.tasksTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  l10n.tasksPageSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: _showSearch ? l10n.close : l10n.searchTasksHint,
                icon: Icon(
                  _showSearch ? Icons.close_rounded : Icons.search_rounded,
                ),
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (!_showSearch) {
                      _searchController.clear();
                      context.read<TaskCubit>().setSearchQuery('');
                    }
                  });
                },
              ),
              IconButton(
                tooltip: l10n.addTask,
                icon: const Icon(Icons.add_task_rounded),
                onPressed: () => TaskFormSheet.show(context),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => TaskFormSheet.show(context),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.addTask,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Summary KPI Cards Row (Pending, Completed, Overdue)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          count: state.totalPendingCount.toString(),
                          label: l10n.tasksSummaryPending,
                          icon: Icons.pending_actions_outlined,
                          color: AppColors.secondary,
                          isSelected: state.activeFilter == TaskFilter.pending,
                          onTap: () => context.read<TaskCubit>().setFilter(
                            TaskFilter.pending,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.space8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          count: state.totalCompletedCount.toString(),
                          label: l10n.tasksSummaryCompleted,
                          icon: Icons.task_alt_rounded,
                          color: AppColors.primary,
                          isSelected:
                              state.activeFilter == TaskFilter.completed,
                          onTap: () => context.read<TaskCubit>().setFilter(
                            TaskFilter.completed,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppConstants.space8),
                      Expanded(
                        child: _buildSummaryCard(
                          context,
                          theme,
                          count: state.totalOverdueCount.toString(),
                          label: l10n.tasksSummaryOverdue,
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.error,
                          isSelected: state.activeFilter == TaskFilter.overdue,
                          onTap: () => context.read<TaskCubit>().setFilter(
                            TaskFilter.overdue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // 2. Search Bar (if opened)
                  if (_showSearch) ...[
                    TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: l10n.searchTasksHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  context.read<TaskCubit>().setSearchQuery('');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.space16,
                          vertical: AppConstants.space12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius12,
                          ),
                        ),
                      ),
                      onChanged: (value) =>
                          context.read<TaskCubit>().setSearchQuery(value),
                    ),
                    const SizedBox(height: AppConstants.space12),
                  ],

                  // 3. Filter Chips Row (All, Pending, Completed, Overdue)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filterOptions.map((opt) {
                        final filter = opt['filter'] as TaskFilter;
                        final label = opt['label'] as String;
                        final isSelected = state.activeFilter == filter;

                        Color chipColor = AppColors.primary;
                        if (filter == TaskFilter.overdue) {
                          chipColor = AppColors.error;
                        } else if (filter == TaskFilter.pending) {
                          chipColor = AppColors.secondary;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(
                            right: AppConstants.space8,
                          ),
                          child: FilterChip(
                            label: Text(label),
                            selected: isSelected,
                            selectedColor: chipColor.withValues(alpha: 0.18),
                            checkmarkColor: chipColor,
                            side: BorderSide(
                              color: isSelected
                                  ? chipColor
                                  : theme.dividerColor.withValues(alpha: 0.4),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? chipColor
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (_) {
                              context.read<TaskCubit>().setFilter(filter);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // 4. Task List / Empty State
                  Expanded(child: _buildTaskList(context, state, l10n)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    ThemeData theme, {
    required String count,
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space12,
        vertical: AppConstants.space12,
      ),
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
          const SizedBox(height: AppConstants.space4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 11,
              color: isSelected
                  ? color
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(
    BuildContext context,
    TaskState state,
    AppLocalizations l10n,
  ) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final tasks = state.filteredTasks;

    if (tasks.isEmpty) {
      return _buildEmptyState(context, state, l10n);
    }

    return ListView.separated(
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppConstants.space12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskCard(
          task: task,
          onToggleCompletion: (completed) {
            context.read<TaskCubit>().toggleTaskCompletion(task.id, completed);
          },
          onEdit: () => TaskFormSheet.show(context, taskToEdit: task),
          onDelete: () => _confirmDelete(context, task, l10n),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    TaskState state,
    AppLocalizations l10n,
  ) {
    String title;
    String message;
    IconData icon;

    if (state.searchQuery.trim().isNotEmpty) {
      title = l10n.emptyTasksSearch;
      message = l10n.emptyTasksSearchDesc;
      icon = Icons.search_off_rounded;
    } else {
      switch (state.activeFilter) {
        case TaskFilter.pending:
          title = l10n.emptyTasksPending;
          message = l10n.emptyTasksPendingDesc;
          icon = Icons.done_all_rounded;
          break;
        case TaskFilter.completed:
          title = l10n.emptyTasksCompleted;
          message = l10n.emptyTasksCompletedDesc;
          icon = Icons.task_alt_rounded;
          break;
        case TaskFilter.overdue:
          title = l10n.emptyTasksOverdue;
          message = l10n.emptyTasksOverdueDesc;
          icon = Icons.thumb_up_alt_outlined;
          break;
        case TaskFilter.all:
          title = l10n.emptyTasksAll;
          message = l10n.emptyTasksAllDesc;
          icon = Icons.checklist_rounded;
          break;
      }
    }

    return ListView(
      children: [
        EmptyStateCard(
          icon: icon,
          title: title,
          message: message,
          action: AppButton(
            text: l10n.addTask,
            onPressed: () => TaskFormSheet.show(context),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
    BuildContext context,
    TaskEntity task,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteTask),
        content: Text('${l10n.deleteTaskConfirm}\n"${task.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<TaskCubit>().deleteTask(task.id);
              Navigator.of(dialogContext).pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
