import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_template_service.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/import_schedule/presentation/screens/import_review_screen.dart';

class ImportSourceSheet extends StatelessWidget {
  const ImportSourceSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => const ImportSourceSheet(),
    );
  }

  void _onChooseCsv(BuildContext context) {
    final cubit = context.read<ImportScheduleCubit>();
    Navigator.of(context).pop();
    cubit.pickAndProcessCsv();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ImportReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.space20,
            vertical: AppConstants.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space16),

              // Header Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppConstants.space10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius12,
                      ),
                    ),
                    child: const Icon(
                      Icons.table_chart_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppConstants.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.importSourceTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppConstants.space2),
                        Text(
                          l10n.offlinePrivateStorage,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space12),

              // Description
              Text(
                l10n.importSourceDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppConstants.space16),

              // Columns Specification Card
              AppCard(
                padding: const EdgeInsets.all(AppConstants.space16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        Text(
                          isArabic
                              ? 'أعمدة ملف CSV المطلوبة'
                              : 'Required CSV Columns',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.space12),
                    _buildColumnItem(
                      theme,
                      name: isArabic ? 'اليوم (Weekday)' : 'Weekday',
                      desc: isArabic
                          ? 'إلزامي (الأحد - السبت)'
                          : 'Required (Sunday - Saturday)',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppConstants.space8),
                    _buildColumnItem(
                      theme,
                      name: isArabic
                          ? 'اسم المقرر (Course Name)'
                          : 'Course Name',
                      desc: isArabic
                          ? 'إلزامي (مثل: خوارزميات)'
                          : 'Required (e.g. Data Structures)',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppConstants.space8),
                    _buildColumnItem(
                      theme,
                      name: isArabic ? 'وقت البدء (Start Time)' : 'Start Time',
                      desc: isArabic
                          ? 'إلزامي (مثل: 09:00 ص أو 09:00)'
                          : 'Required (e.g. 09:00 AM)',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppConstants.space8),
                    _buildColumnItem(
                      theme,
                      name: isArabic ? 'وقت الانتهاء (End Time)' : 'End Time',
                      desc: isArabic
                          ? 'إلزامي (مثل: 10:30 ص أو 10:30)'
                          : 'Required (e.g. 10:30 AM)',
                      isRequired: true,
                    ),
                    const SizedBox(height: AppConstants.space8),
                    _buildColumnItem(
                      theme,
                      name: isArabic ? 'المحاضر (Instructor)' : 'Instructor',
                      desc: isArabic
                          ? 'اختياري (مثل: د. أحمد)'
                          : 'Optional (e.g. Dr. Smith)',
                      isRequired: false,
                    ),
                    const SizedBox(height: AppConstants.space8),
                    _buildColumnItem(
                      theme,
                      name: isArabic ? 'القاعة (Room)' : 'Room',
                      desc: isArabic
                          ? 'اختياري (مثل: قاعة 101 أو معمل 2)'
                          : 'Optional (e.g. Hall 101, Lab 3)',
                      isRequired: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.space20),

              // Action 1: Select CSV File
              AppButton(
                text: isArabic
                    ? 'اختيار ملف CSV (.csv)'
                    : 'Select CSV File (.csv)',
                icon: const Icon(
                  Icons.upload_file_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => _onChooseCsv(context),
              ),
              const SizedBox(height: AppConstants.space12),

              // Action 2: Download or Copy Template
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  TimetableTemplateService.showTemplateSheet(context);
                },
                icon: const Icon(Icons.file_download_outlined, size: 18),
                label: Text(l10n.downloadCsvTemplate),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.space12,
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnItem(
    ThemeData theme, {
    required String name,
    required String desc,
    required bool isRequired,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isRequired ? AppColors.primary : AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppConstants.space8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall,
              children: [
                TextSpan(
                  text: '$name: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: desc,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
