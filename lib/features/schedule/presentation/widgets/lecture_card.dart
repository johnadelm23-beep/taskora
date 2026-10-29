import 'package:flutter/material.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/status_badge.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';

class LectureCard extends StatelessWidget {
  final LectureEntity lecture;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const LectureCard({
    super.key,
    required this.lecture,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = lecture.colorHex != null
        ? Color(lecture.colorHex!)
        : AppColors.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Name & Code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture.courseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (lecture.courseCode.isNotEmpty) ...[
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        lecture.courseCode,
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
              // Time Badge
              StatusBadge(
                label: '${lecture.startTime} - ${lecture.endTime}',
                color: accentColor,
                icon: Icons.access_time_rounded,
              ),
              if (onEdit != null) ...[
                const SizedBox(width: AppConstants.space8),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  tooltip: 'Edit Lecture',
                  onPressed: onEdit,
                ),
              ],
              if (onDelete != null) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: 'Delete Lecture',
                  onPressed: onDelete,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppConstants.space12),
          const Divider(height: 1),
          const SizedBox(height: AppConstants.space12),
          // Room & Instructor Row
          Row(
            children: [
              if (lecture.room.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.room_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: AppConstants.space4),
                    Text(
                      lecture.room,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: AppConstants.space16),
              ],
              if (lecture.instructor.isNotEmpty) ...[
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      const SizedBox(width: AppConstants.space4),
                      Expanded(
                        child: Text(
                          lecture.instructor,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (lecture.notes != null && lecture.notes!.isNotEmpty) ...[
            const SizedBox(height: AppConstants.space8),
            Text(
              lecture.notes!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
