import 'package:flutter/material.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';

class FeatureBottomSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String description;
  final List<Widget>? actionItems;

  const FeatureBottomSheet({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.description,
    this.actionItems,
  });

  static Future<void> show(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String description,
    List<Widget>? actionItems,
  }) {
    final theme = Theme.of(context);
    return showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => FeatureBottomSheet(
        icon: icon,
        title: title,
        subtitle: subtitle,
        description: description,
        actionItems: actionItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppConstants.space20,
          AppConstants.space12,
          AppConstants.space20,
          AppConstants.space20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            const SizedBox(height: AppConstants.space20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.space12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppConstants.space16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space4),
                      Text(
                        subtitle ?? l10n.featureComingSoon,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space16),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            if (actionItems != null && actionItems!.isNotEmpty) ...[
              const SizedBox(height: AppConstants.space16),
              ...actionItems!,
            ],
            const SizedBox(height: AppConstants.space24),
            AppButton(
              text: l10n.gotIt,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
