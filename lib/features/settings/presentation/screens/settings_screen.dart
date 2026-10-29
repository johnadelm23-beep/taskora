import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/section_header.dart';
import 'package:taskora/core/widgets/status_badge.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.space16),
          children: [
            // Section 1: Preferences
            SectionHeader(title: l10n.preferencesSection),
            const SizedBox(height: AppConstants.space4),

            // Theme Mode Selector
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppConstants.space8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius8,
                        ),
                      ),
                      child: const Icon(
                        Icons.palette_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.themeMode,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_getThemeModeName(l10n, themeMode)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: _getThemeModeName(l10n, themeMode),
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                    onTap: () => _showThemeModeDialog(context, l10n, themeMode),
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.space12),

            // Language Selector
            BlocBuilder<LocaleCubit, Locale?>(
              builder: (context, locale) {
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(AppConstants.space8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius8,
                        ),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l10n.language,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_getLanguageName(l10n, locale)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusBadge(
                          label: locale?.languageCode == 'ar'
                              ? 'العربية'
                              : 'EN',
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        const Icon(Icons.chevron_right_rounded, size: 20),
                      ],
                    ),
                    onTap: () => _showLanguageDialog(context, l10n, locale),
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.space24),

            // Section 2: Storage & Privacy
            SectionHeader(title: l10n.storagePrivacySection),
            const SizedBox(height: AppConstants.space4),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.space8),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius8,
                          ),
                        ),
                        child: const Icon(
                          Icons.verified_user_outlined,
                          color: AppColors.tertiary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppConstants.space12),
                      Expanded(
                        child: Text(
                          l10n.offlinePrivateStorage,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const StatusBadge(
                        label: 'Active',
                        color: AppColors.tertiary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space8),
                  Text(
                    l10n.offlinePrivateDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space24),

            // Section 3: About
            SectionHeader(title: l10n.aboutTitle),
            const SizedBox(height: AppConstants.space4),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppConstants.space8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(
                            AppConstants.radius8,
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppConstants.space12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              l10n.appVersion,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: AppConstants.space24),
                  Row(
                    children: [
                      const Icon(
                        Icons.architecture_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: AppConstants.space8),
                      Text(
                        l10n.aboutArchitecture,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.space4),
                  Text(
                    l10n.aboutArchitectureDesc,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.75,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeModeName(AppLocalizations l10n, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.themeLight;
      case ThemeMode.dark:
        return l10n.themeDark;
      case ThemeMode.system:
        return l10n.themeSystem;
    }
  }

  String _getLanguageName(AppLocalizations l10n, Locale? locale) {
    if (locale?.languageCode == 'ar') {
      return l10n.langArabic;
    }
    return l10n.langEnglish;
  }

  void _showThemeModeDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeMode currentMode,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.themeMode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOptionTile(
                dialogContext,
                context,
                title: l10n.themeSystem,
                mode: ThemeMode.system,
                isSelected: currentMode == ThemeMode.system,
              ),
              _buildThemeOptionTile(
                dialogContext,
                context,
                title: l10n.themeLight,
                mode: ThemeMode.light,
                isSelected: currentMode == ThemeMode.light,
              ),
              _buildThemeOptionTile(
                dialogContext,
                context,
                title: l10n.themeDark,
                mode: ThemeMode.dark,
                isSelected: currentMode == ThemeMode.dark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionTile(
    BuildContext dialogContext,
    BuildContext parentContext, {
    required String title,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: AppColors.primary)
          : null,
      onTap: () {
        parentContext.read<ThemeCubit>().setThemeMode(mode);
        Navigator.of(dialogContext).pop();
      },
    );
  }

  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    Locale? currentLocale,
  ) {
    final currentCode = currentLocale?.languageCode ?? 'en';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(l10n.langEnglish),
                trailing: currentCode == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<LocaleCubit>().setLocale(const Locale('en'));
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                title: Text(l10n.langArabic),
                trailing: currentCode == 'ar'
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<LocaleCubit>().setLocale(const Locale('ar'));
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
