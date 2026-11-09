import 'dart:async';
import 'package:flutter/material.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/empty_state_card.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/domain/services/schedule_csv_exporter.dart';

/// Modal bottom sheet allowing users to preview, customize language, and export
/// their saved timetable records to a CSV file or copy to the clipboard.
class ExportScheduleSheet extends StatefulWidget {
  final List<LectureEntity> lectures;

  const ExportScheduleSheet({super.key, required this.lectures});

  static Future<void> show(
    BuildContext context, {
    required List<LectureEntity> lectures,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => ExportScheduleSheet(lectures: lectures),
    );
  }

  @override
  State<ExportScheduleSheet> createState() => _ExportScheduleSheetState();
}

class _ExportScheduleSheetState extends State<ExportScheduleSheet> {
  late bool _isArabic;
  bool _saving = false;
  bool _copied = false;
  Timer? _copyResetTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isArabic = Localizations.localeOf(context).languageCode == 'ar';
  }

  @override
  void dispose() {
    _copyResetTimer?.cancel();
    super.dispose();
  }

  String get _csvContent {
    return ScheduleCsvExporter.generateCsv(
      widget.lectures,
      isArabic: _isArabic,
    );
  }

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    final savedPath = await ScheduleCsvExporter.saveCsvFile(
      _csvContent,
      defaultFileName: 'taskora_schedule_${_isArabic ? "ar" : "en"}.csv',
    );
    if (mounted) {
      setState(() => _saving = false);
      if (savedPath != null) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timetable CSV saved successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleCopy() async {
    await ScheduleCsvExporter.copyToClipboard(_csvContent);
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timetable CSV copied to clipboard!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      _copyResetTimer?.cancel();
      _copyResetTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (widget.lectures.isEmpty) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmptyStateCard(
                icon: Icons.event_busy_outlined,
                title: 'No Classes to Export',
                message:
                    'Your schedule is currently empty. Add classes before exporting your timetable.',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.gotIt),
                ),
              ),
            ],
          ),
        ),
      );
    }

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
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppConstants.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArabic
                            ? 'تصدير الجدول الدراسي (CSV)'
                            : 'Export Timetable (CSV)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppConstants.space2),
                      Text(
                        '${widget.lectures.length} ${_isArabic ? "محاضرة محفوظة" : "saved classes"} • UTF-8 BOM',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space12),

            // Language Selector Toggle
            Row(
              children: [
                Text(
                  _isArabic ? 'لغة التصدير:' : 'Export Language:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(value: false, label: Text('English')),
                    ButtonSegment<bool>(value: true, label: Text('العربية')),
                  ],
                  selected: {_isArabic},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isArabic = newSelection.first;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: AppConstants.space12),

            // Preview Box
            Container(
              height: 160,
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
                  _csvContent,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space20),

            // Action Buttons: Copy / Share & Save CSV File
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleCopy,
                    icon: Icon(
                      _copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 18,
                    ),
                    label: Text(_copied ? 'Copied!' : 'Copy to Clipboard'),
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
                    text: _saving ? 'Saving...' : 'Save CSV File',
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
            const SizedBox(height: AppConstants.space8),
          ],
        ),
      ),
    );
  }
}
