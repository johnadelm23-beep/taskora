import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/status_badge.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';

class TaskCard extends StatelessWidget {
  final TaskEntity task;
  final ValueChanged<bool>? onToggleCompletion;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.onToggleCompletion,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    // Priority color and label
    final (priorityColor, priorityLabel) = switch (task.priority) {
      TaskPriority.high => (AppColors.error, l10n.priorityHigh),
      TaskPriority.medium => (AppColors.secondary, l10n.priorityMedium),
      TaskPriority.low => (AppColors.tertiary, l10n.priorityLow),
    };

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Completion Checkbox
              IconButton(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(),
                icon: Icon(
                  task.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: task.isCompleted
                      ? AppColors.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  size: 24,
                ),
                tooltip: task.isCompleted
                    ? 'Mark as incomplete'
                    : 'Mark as completed',
                onPressed: onToggleCompletion != null
                    ? () => onToggleCompletion!(!task.isCompleted)
                    : null,
              ),
              const SizedBox(width: AppConstants.space12),

              // 2. Title & Course
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.45,
                              )
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (task.courseName != null &&
                        task.courseName!.trim().isNotEmpty) ...[
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        task.courseName!.trim(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // 3. Action Buttons (Edit & Delete)
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  tooltip: l10n.editTask,
                  onPressed: onEdit,
                ),
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: l10n.deleteTask,
                  onPressed: onDelete,
                ),
            ],
          ),

          // 4. Description (if any)
          if (task.description != null &&
              task.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                task.description!.trim(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: task.isCompleted ? 0.35 : 0.6,
                  ),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const SizedBox(height: AppConstants.space12),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.space12),

          // 5. Badges: Deadline + Priority + Overdue/Completed status
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Deadline Badge
              if (task.dueDate != null)
                _buildDeadlineBadge(context, task, l10n),

              // Priority Badge
              StatusBadge(
                label: priorityLabel,
                color: priorityColor,
                icon: Icons.flag_rounded,
              ),

              // Overdue or Completed indicator
              if (task.isCompleted)
                StatusBadge(
                  label: l10n.taskCompleted,
                  color: AppColors.primary,
                  icon: Icons.task_alt_rounded,
                )
              else if (task.isOverdue)
                StatusBadge(
                  label: l10n.taskOverdue,
                  color: AppColors.error,
                  icon: Icons.warning_amber_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineBadge(
    BuildContext context,
    TaskEntity task,
    AppLocalizations l10n,
  ) {
    final localDue = task.dueDate!.toLocal();
    final timeStr = DateFormat('HH:mm').format(localDue);

    String dateStr;
    if (task.isDueToday) {
      dateStr = '${l10n.dueToday}, $timeStr';
    } else if (task.isDueTomorrow) {
      dateStr = '${l10n.dueTomorrow}, $timeStr';
    } else {
      dateStr = '${DateFormat('MMM d').format(localDue)}, $timeStr';
    }

    final isOverdue = task.isOverdue;

    return StatusBadge(
      label: dateStr,
      color: isOverdue ? AppColors.error : AppColors.secondary,
      icon: isOverdue ? Icons.error_outline_rounded : Icons.access_time_rounded,
    );
  }
}
