import 'package:flutter/material.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/status_badge.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';

class CandidateLectureCard extends StatelessWidget {
  final ExtractedLectureCandidate candidate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CandidateLectureCard({
    super.key,
    required this.candidate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final days = [
      l10n.translate('day_sun'),
      l10n.translate('day_mon'),
      l10n.translate('day_tue'),
      l10n.translate('day_wed'),
      l10n.translate('day_thu'),
      l10n.translate('day_fri'),
      l10n.translate('day_sat'),
    ];

    final hasValidDay =
        candidate.dayOfWeek != null &&
        candidate.dayOfWeek! >= 0 &&
        candidate.dayOfWeek! < 7;
    final dayText = hasValidDay
        ? days[candidate.dayOfWeek!]
        : l10n.importMissingDay;

    // Card border color based on validation/conflict status
    Color? borderColor;
    if (!candidate.isValid) {
      borderColor = AppColors.error.withValues(alpha: 0.6);
    } else if (candidate.hasConflict) {
      borderColor = AppColors.warning.withValues(alpha: 0.6);
    } else if (candidate.isDuplicate) {
      borderColor = AppColors.info.withValues(alpha: 0.6);
    }

    final accentColor = candidate.colorHex != null
        ? Color(candidate.colorHex!)
        : AppColors.primary;

    return AppCard(
      onTap: onEdit,
      borderColor: borderColor,
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Course info & Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (candidate.courseName.trim().isNotEmpty) ...[
                      Text(
                        candidate.courseName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 18,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppConstants.space6),
                          Text(
                            l10n.importMissingTitle,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (candidate.courseCode.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        candidate.courseCode,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.65,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Action buttons: Edit & Delete
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                tooltip: l10n.importEditCandidate,
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: AppColors.error,
                tooltip: l10n.delete,
                onPressed: onDelete,
              ),
            ],
          ),

          const SizedBox(height: AppConstants.space8),

          // Day and Time chips
          Wrap(
            spacing: AppConstants.space8,
            runSpacing: AppConstants.space6,
            children: [
              // Weekday chip
              StatusBadge(
                label: dayText,
                color: hasValidDay ? accentColor : AppColors.error,
                icon: Icons.calendar_today_rounded,
              ),
              // Time chip
              StatusBadge(
                label:
                    '${candidate.startTime ?? '--:--'} - ${candidate.endTime ?? '--:--'}',
                color: candidate.isTimeRangeValid
                    ? accentColor
                    : AppColors.error,
                icon: candidate.isTimeRangeValid
                    ? Icons.access_time_rounded
                    : Icons.error_outline_rounded,
              ),
            ],
          ),

          // Location and Instructor if available
          if (candidate.room.isNotEmpty || candidate.instructor.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Row(
              children: [
                if (candidate.room.isNotEmpty) ...[
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.room_outlined,
                          size: 15,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: AppConstants.space4),
                        Flexible(
                          child: Text(
                            candidate.room,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (candidate.room.isNotEmpty &&
                    candidate.instructor.isNotEmpty) ...[
                  const SizedBox(width: AppConstants.space16),
                ],
                if (candidate.instructor.isNotEmpty) ...[
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 15,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: AppConstants.space4),
                        Flexible(
                          child: Text(
                            candidate.instructor,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Status & Warning Badges
          if (!candidate.isValid ||
              candidate.hasConflict ||
              candidate.isDuplicate) ...[
            const SizedBox(height: AppConstants.space8),
            const Divider(height: 1),
            const SizedBox(height: AppConstants.space8),
            Wrap(
              spacing: AppConstants.space8,
              runSpacing: AppConstants.space4,
              children: [
                if (!candidate.isValid)
                  for (final err in candidate.validationErrors)
                    _StatusTag(
                      label: err,
                      icon: Icons.error_outline_rounded,
                      color: AppColors.error,
                    ),
                if (candidate.isValid && candidate.isDuplicate)
                  _StatusTag(
                    label: l10n.importDuplicateBadge,
                    icon: Icons.copy_rounded,
                    color: AppColors.info,
                  ),
                if (candidate.isValid && candidate.hasConflict)
                  _StatusTag(
                    label: candidate.conflictReason ?? l10n.importConflictBadge,
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _StatusTag({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space8,
        vertical: AppConstants.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppConstants.space4),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
