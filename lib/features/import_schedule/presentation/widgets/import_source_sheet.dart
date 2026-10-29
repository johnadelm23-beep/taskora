import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
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

  void _onSelectSource(BuildContext context, VoidCallback action) {
    Navigator.of(context).pop();
    action();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ImportReviewScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ImportScheduleCubit>();

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
                      Icons.document_scanner_rounded,
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
              const SizedBox(height: AppConstants.space20),

              // Option 1: Gallery
              _SourceOptionTile(
                icon: Icons.photo_library_outlined,
                title: l10n.importFromGallery,
                subtitle: 'Screenshot, saved image, or photo',
                color: AppColors.primary,
                onTap: () => _onSelectSource(
                  context,
                  () => cubit.pickAndProcessImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(height: AppConstants.space12),

              // Option 2: Camera
              _SourceOptionTile(
                icon: Icons.camera_alt_outlined,
                title: l10n.importFromCamera,
                subtitle: 'Capture printed paper schedule',
                color: const Color(0xFF00897B),
                onTap: () => _onSelectSource(
                  context,
                  () => cubit.pickAndProcessImage(ImageSource.camera),
                ),
              ),
              const SizedBox(height: AppConstants.space12),

              // Option 3: PDF Document
              _SourceOptionTile(
                icon: Icons.picture_as_pdf_outlined,
                title: l10n.importFromPdf,
                subtitle: 'Selectable text or digital university PDF',
                color: const Color(0xFFE53935),
                onTap: () =>
                    _onSelectSource(context, () => cubit.pickAndProcessPdf()),
              ),
              const SizedBox(height: AppConstants.space12),

              // Option 4: Standard CSV Template
              _SourceOptionTile(
                icon: Icons.table_chart_outlined,
                title: l10n.importFromCsv,
                subtitle: l10n.importFromCsvDesc,
                color: const Color(0xFF673AB7),
                onTap: () =>
                    _onSelectSource(context, () => cubit.pickAndProcessCsv()),
              ),
              const SizedBox(height: AppConstants.space16),

              // Download / View CSV Template Link
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    TimetableTemplateService.showTemplateSheet(context);
                  },
                  icon: const Icon(Icons.file_download_outlined, size: 18),
                  label: Text(l10n.downloadCsvTemplate),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w600),
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
}

class _SourceOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SourceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppConstants.space16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.space10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppConstants.space16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.space2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
