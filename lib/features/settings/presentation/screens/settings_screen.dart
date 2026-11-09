import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/localization/locale_cubit.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/app/theme/app_icons.dart';
import 'package:taskora/app/theme/theme_cubit.dart';
import 'package:taskora/core/backup/backup_payload.dart';
import 'package:taskora/core/backup/backup_service.dart';
import 'package:taskora/core/di/injection_container.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_card.dart';
import 'package:taskora/core/widgets/section_header.dart';
import 'package:taskora/core/widgets/status_badge.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_cubit.dart';
import 'package:taskora/features/reminders/presentation/cubit/reminders_state.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';
import 'package:taskora/features/schedule/presentation/widgets/export_schedule_sheet.dart';

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
                        AppIcons.theme,
                        color: AppColors.primary,
                        size: AppIcons.sizeMedium,
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
                        const Icon(
                          AppIcons.chevronRight,
                          size: AppIcons.sizeMedium,
                        ),
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
                        AppIcons.language,
                        color: AppColors.secondary,
                        size: AppIcons.sizeMedium,
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
                        const Icon(
                          AppIcons.chevronRight,
                          size: AppIcons.sizeMedium,
                        ),
                      ],
                    ),
                    onTap: () => _showLanguageDialog(context, l10n, locale),
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.space24),

            // Section 2: Notifications & Reminders
            SectionHeader(title: l10n.notificationsSection),
            const SizedBox(height: AppConstants.space4),
            BlocBuilder<RemindersCubit, RemindersState>(
              builder: (context, remindersState) {
                final remindersCubit = context.read<RemindersCubit>();
                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        secondary: Container(
                          padding: const EdgeInsets.all(AppConstants.space8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radius8,
                            ),
                          ),
                          child: const Icon(
                            AppIcons.notificationsActive,
                            color: AppColors.primary,
                            size: AppIcons.sizeMedium,
                          ),
                        ),
                        title: Text(
                          l10n.lectureReminders,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(l10n.lectureRemindersDesc),
                        value: remindersState.lectureRemindersEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (enabled) {
                          remindersCubit.toggleLectureReminders(enabled);
                        },
                      ),
                      Divider(
                        height: 1,
                        indent: AppConstants.space16,
                        endIndent: AppConstants.space16,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                      ),
                      SwitchListTile.adaptive(
                        secondary: Container(
                          padding: const EdgeInsets.all(AppConstants.space8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppConstants.radius8,
                            ),
                          ),
                          child: const Icon(
                            AppIcons.notifications,
                            color: AppColors.secondary,
                            size: AppIcons.sizeMedium,
                          ),
                        ),
                        title: Text(
                          l10n.taskReminders,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(l10n.taskRemindersDesc),
                        value: remindersState.taskRemindersEnabled,
                        activeTrackColor: AppColors.primary,
                        onChanged: (enabled) {
                          remindersCubit.toggleTaskReminders(enabled);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppConstants.space24),

            // Section 3: Storage & Privacy
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
                          AppIcons.backup,
                          color: AppColors.tertiary,
                          size: AppIcons.sizeMedium,
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
            const SizedBox(height: AppConstants.space12),

            // Export Schedule CSV Tile
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.space8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: const Icon(
                    AppIcons.csvExport,
                    color: AppColors.secondary,
                    size: AppIcons.sizeMedium,
                  ),
                ),
                title: const Text(
                  'Export Timetable (CSV)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Export schedule to UTF-8 BOM CSV file'),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: AppIcons.sizeMedium,
                ),
                onTap: () {
                  final lectures = context
                      .read<ScheduleCubit>()
                      .state
                      .allLectures;
                  ExportScheduleSheet.show(context, lectures: lectures);
                },
              ),
            ),
            const SizedBox(height: AppConstants.space12),

            // Backup Database Tile
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.space8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: const Icon(
                    AppIcons.backup,
                    color: AppColors.primary,
                    size: AppIcons.sizeMedium,
                  ),
                ),
                title: Text(
                  l10n.backupTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.backupDesc),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: AppIcons.sizeMedium,
                ),
                onTap: () => _handleCreateBackup(context, l10n),
              ),
            ),
            const SizedBox(height: AppConstants.space12),

            // Restore Database Tile
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppConstants.space8),
                  decoration: BoxDecoration(
                    color: AppColors.tertiary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius8),
                  ),
                  child: const Icon(
                    AppIcons.csvImport,
                    color: AppColors.tertiary,
                    size: AppIcons.sizeMedium,
                  ),
                ),
                title: Text(
                  l10n.restoreTitle,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(l10n.restoreDesc),
                trailing: const Icon(
                  AppIcons.chevronRight,
                  size: AppIcons.sizeMedium,
                ),
                onTap: () => _handleRestoreBackup(context, l10n),
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius8,
                        ),
                        child: Image.asset(
                          'assets/images/logo/taskora_icon_solid.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
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
          ? const Icon(AppIcons.check, color: AppColors.primary)
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
                    ? const Icon(AppIcons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  context.read<LocaleCubit>().setLocale(const Locale('en'));
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                title: Text(l10n.langArabic),
                trailing: currentCode == 'ar'
                    ? const Icon(AppIcons.check, color: AppColors.primary)
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

  Future<void> _handleCreateBackup(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      final backupService = sl<BackupService>();
      final jsonStr = await backupService.createBackupJson();
      final path = await backupService.saveBackupToFile(jsonStr);
      if (path != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.backupSuccess),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    try {
      final backupService = sl<BackupService>();
      final payload = await backupService.pickAndValidateBackup();
      if (payload == null) return; // User dismissed picker

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.restoreConfirmTitle),
            content: Text(
              'Found ${payload.lectures.length} lectures and ${payload.tasks.length} tasks in this backup file.\n\n${l10n.restoreConfirmDesc}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.close),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.restoreBtn),
              ),
            ],
          );
        },
      );

      if (confirmed == true && context.mounted) {
        await backupService.restoreBackup(payload);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.restoreSuccess} (${payload.lectures.length} lectures, ${payload.tasks.length} tasks)',
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on BackupValidationException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.restoreInvalidFile}: ${e.message}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
