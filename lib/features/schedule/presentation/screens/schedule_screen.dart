import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/empty_state_card.dart';
import 'package:taskora/core/widgets/status_badge.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/import_source_sheet.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_state.dart';
import 'package:taskora/features/schedule/presentation/widgets/lecture_card.dart';
import 'package:taskora/features/schedule/presentation/widgets/lecture_form_sheet.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final days = [
      l10n.translate('day_sun'),
      l10n.translate('day_mon'),
      l10n.translate('day_tue'),
      l10n.translate('day_wed'),
      l10n.translate('day_thu'),
      l10n.translate('day_fri'),
      l10n.translate('day_sat'),
    ];

    return BlocConsumer<ScheduleCubit, ScheduleState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final selectedDay = state.selectedDayIndex;
        final dayLectures = state.dayLectures;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  l10n.schedulePageSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: l10n.importSchedule,
                icon: const Icon(Icons.document_scanner_outlined),
                onPressed: () => _showImportSheet(context, l10n),
              ),
              IconButton(
                tooltip: l10n.addLecture,
                icon: const Icon(Icons.add_rounded),
                onPressed: () => LectureFormSheet.show(
                  context,
                  initialDayIndex: selectedDay,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                LectureFormSheet.show(context, initialDayIndex: selectedDay),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              l10n.addLecture,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Days of week selector
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(days.length, (index) {
                        final isSelected = index == selectedDay;
                        final count = state.allLectures
                            .where((l) => l.dayOfWeek == index)
                            .length;

                        return Padding(
                          padding: const EdgeInsets.only(
                            right: AppConstants.space8,
                          ),
                          child: ChoiceChip(
                            label: Text(
                              count > 0
                                  ? '${days[index]} ($count)'
                                  : days[index],
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                context.read<ScheduleCubit>().selectDay(index);
                              }
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // Day Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        days[selectedDay],
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusBadge(
                        label: '${dayLectures.length} classes',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space16),

                  // Schedule List / Empty State
                  Expanded(
                    child: dayLectures.isEmpty
                        ? ListView(
                            children: [
                              EmptyStateCard(
                                icon: Icons.calendar_month_rounded,
                                title: l10n.emptyDayLectures,
                                message: l10n.emptyDayDesc,
                                action: Wrap(
                                  spacing: AppConstants.space8,
                                  runSpacing: AppConstants.space8,
                                  alignment: WrapAlignment.center,
                                  children: [
                                    AppButton(
                                      text: l10n.addLecture,
                                      onPressed: () => LectureFormSheet.show(
                                        context,
                                        initialDayIndex: selectedDay,
                                      ),
                                    ),
                                    AppButton(
                                      text: l10n.importSchedule,
                                      isOutlined: true,
                                      onPressed: () =>
                                          _showImportSheet(context, l10n),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            itemCount: dayLectures.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppConstants.space12),
                            itemBuilder: (context, index) {
                              final lecture = dayLectures[index];
                              return LectureCard(
                                lecture: lecture,
                                onEdit: () => LectureFormSheet.show(
                                  context,
                                  lectureToEdit: lecture,
                                ),
                                onDelete: () => _confirmDelete(
                                  context,
                                  lecture.id,
                                  lecture.courseName,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int id, String courseName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Lecture'),
        content: Text('Are you sure you want to remove "$courseName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              context.read<ScheduleCubit>().deleteLecture(id);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImportSheet(BuildContext context, AppLocalizations l10n) {
    ImportSourceSheet.show(context);
  }
}
