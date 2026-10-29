import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';

/// Service providing downloadable, shareable, and copyable standard timetable CSV templates.
class TimetableTemplateService {
  /// Standard timetable CSV template content.
  /// Exactly conforms to the standard schema:
  /// Weekday,Course Name,Start Time,End Time,Instructor,Room
  static const String templateCsv =
      'Weekday,Course Name,Start Time,End Time,Instructor,Room\r\n'
      '# EXAMPLES (Delete or replace with your own courses):\r\n'
      '# Sunday,Algorithms & Data Structures,09:00 AM,10:30 AM,Dr. Ahmed Hassan,Hall 101\r\n'
      '# Monday,Database Systems,11:00 AM,12:30 PM,Prof. Sara Ibrahim,Lab 3\r\n'
      '# Tuesday,Computer Networks,02:00 PM,03:30 PM,Dr. Mohamed Tarek,Room 204\r\n'
      '# Wednesday,Operating Systems,09:00 AM,10:30 AM,,Room 105\r\n'
      '# Thursday,Software Engineering,08:30 AM,10:00 AM,Dr. Nour Samir,Room 301\r\n'
      '# الأحد,برمجة الويب,09:00 ص,10:30 ص,د. سارة عادل,معمل 2\r\n'
      '# الاثنين,الذكاء الاصطناعي,11:00 ص,12:30 م,م. عمر خالد,قاعة 302\r\n';

  /// Copies the CSV template content to the system clipboard.
  static Future<bool> copyToClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: templateCsv));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user to save the template CSV file to their device.
  static Future<String?> saveTemplateFile() async {
    try {
      final bytes = utf8.encode(templateCsv);
      final resultPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Timetable CSV Template',
        fileName: 'taskora_timetable_template.csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );

      // On desktop or platforms where saveFile returns path without auto-writing bytes
      if (resultPath != null && resultPath.isNotEmpty) {
        final file = File(resultPath);
        if (!await file.exists() || (await file.length()) == 0) {
          await file.writeAsBytes(bytes, flush: true);
        }
      }

      return resultPath;
    } catch (_) {
      return null;
    }
  }

  /// Shows an interactive bottom sheet for previewing, copying, or saving the CSV template.
  static Future<void> showTemplateSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (sheetContext) => const _TemplatePreviewSheet(),
    );
  }
}

class _TemplatePreviewSheet extends StatefulWidget {
  const _TemplatePreviewSheet();

  @override
  State<_TemplatePreviewSheet> createState() => _TemplatePreviewSheetState();
}

class _TemplatePreviewSheetState extends State<_TemplatePreviewSheet> {
  bool _copied = false;
  bool _saving = false;

  Future<void> _handleCopy() async {
    await TimetableTemplateService.copyToClipboard();
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).csvTemplateCopied),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    final savedPath = await TimetableTemplateService.saveTemplateFile();
    if (mounted) {
      setState(() => _saving = false);
      if (savedPath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).csvTemplateSaved),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space20,
          vertical: AppConstants.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.space10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: const Icon(
                    Icons.table_view_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.downloadCsvTemplate,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space2),
                      Text(
                        'Standard Timetable Format',
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
            const SizedBox(height: AppConstants.space12),

            // Explanation
            Text(
              l10n.downloadCsvTemplateDesc,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: AppConstants.space16),

            // Code Preview Box
            Container(
              height: 180,
              padding: const EdgeInsets.all(AppConstants.space12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(AppConstants.radius12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  TimetableTemplateService.templateCsv,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleCopy,
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(_copied ? 'Copied!' : l10n.copyToClipboard),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.space12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: AppButton(
                    text: _saving ? 'Saving...' : l10n.saveCsvFile,
                    icon: const Icon(
                      Icons.file_download_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: _saving ? null : _handleSave,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space12),
          ],
        ),
      ),
    );
  }
}
