import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/core/widgets/empty_state_card.dart';
import 'package:taskora/features/import_schedule/domain/services/timetable_template_service.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_cubit.dart';
import 'package:taskora/features/import_schedule/presentation/cubit/import_schedule_state.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/candidate_lecture_card.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/edit_candidate_sheet.dart';
import 'package:taskora/features/import_schedule/presentation/widgets/import_source_sheet.dart';
import 'package:taskora/features/shell/presentation/cubit/navigation_cubit.dart';

class ImportReviewScreen extends StatelessWidget {
  const ImportReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<ImportScheduleCubit, ImportScheduleState>(
      listener: (context, state) {
        if (state.status == ImportStatus.failure &&
            state.errorMessage != null) {
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
        final cubit = context.read<ImportScheduleCubit>();

        return Scaffold(
          appBar: AppBar(
            title: Text(
              l10n.importReviewTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.table_view_outlined),
                tooltip: l10n.downloadCsvTemplate,
                onPressed: () =>
                    TimetableTemplateService.showTemplateSheet(context),
              ),
              if (state.status == ImportStatus.review)
                IconButton(
                  icon: const Icon(Icons.file_upload_outlined),
                  tooltip: l10n.importSourceTitle,
                  onPressed: () => ImportSourceSheet.show(context),
                ),
            ],
          ),
          body: _buildBody(context, state, cubit, l10n, theme),
          bottomNavigationBar:
              ((state.status == ImportStatus.review ||
                      state.status == ImportStatus.initial) &&
                  state.candidates.isNotEmpty)
              ? _buildBottomBar(context, state, cubit, l10n, theme)
              : null,
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    ImportScheduleState state,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    switch (state.status) {
      case ImportStatus.picking:
      case ImportStatus.processing:
        return _buildProcessingView(context, state, cubit, l10n, theme);

      case ImportStatus.saving:
        return _buildSavingView(context, l10n, theme);

      case ImportStatus.success:
        return _buildSuccessView(context, state, l10n, theme);

      case ImportStatus.initial:
      case ImportStatus.failure:
      case ImportStatus.review:
        if (state.candidates.isEmpty) {
          return _buildEmptyCandidatesView(context, cubit, l10n, theme);
        }
        return _buildCandidatesListView(context, state, cubit, l10n, theme);
    }
  }

  Widget _buildProcessingView(
    BuildContext context,
    ImportScheduleState state,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final message =
        state.processingMessage ??
        (state.sourceFilePath?.toLowerCase().endsWith('.pdf') == true
            ? l10n.importProcessingPdf
            : l10n.importProcessingOcr);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.space20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.space24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.space12,
                vertical: AppConstants.space6,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.radius8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: AppConstants.space6),
                  Text(
                    l10n.offlinePrivateStorage,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.space32),
            OutlinedButton(
              onPressed: () {
                cubit.cancelProcessing();
                Navigator.of(context).pop();
              },
              child: Text(l10n.close),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingView(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: AppConstants.space20),
          Text(
            l10n.importSavingMessage,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(
    BuildContext context,
    ImportScheduleState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final result = state.result;
    final importedCount = result?.importedCount ?? state.candidates.length;
    final duplicatesCount = result?.skippedDuplicatesCount ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.space20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppConstants.space24),
            Text(
              l10n.importSuccessTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.space8),
            Text(
              '$importedCount ${l10n.importSuccessMessage}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (duplicatesCount > 0) ...[
              const SizedBox(height: AppConstants.space12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.space12,
                  vertical: AppConstants.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.radius8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppConstants.space8),
                    Text(
                      '$duplicatesCount ${l10n.importSkippedDuplicates}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppConstants.space32),
            AppButton(
              text: l10n.importViewSchedule,
              icon: const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () {
                // Switch to schedule tab (index 1) and pop to root
                context.read<NavigationCubit>().selectTab(1);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCandidatesView(
    BuildContext context,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmptyStateCard(
            icon: Icons.find_in_page_outlined,
            title: l10n.importEmptyTitle,
            message: l10n.importEmptyDesc,
          ),
          const SizedBox(height: AppConstants.space16),

          // Diagnostic / Explanation box explaining why automatic extraction failed
          Container(
            padding: const EdgeInsets.all(AppConstants.space16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radius12),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppConstants.space8),
                    Text(
                      'Why did recognition fail?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space8),
                Text(
                  '• Timetables need readable weekdays (Sunday–Saturday) and clear time ranges (e.g., 09:00 - 10:30).\n'
                  '• Scanned documents or compressed screenshots may have blurred text.\n'
                  '• You can use our standard CSV template for 100% accurate, instant import, or add your classes manually.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.space20),

          // Option 1: Import CSV Template
          AppButton(
            text: l10n.importFromCsv,
            icon: const Icon(
              Icons.table_chart_outlined,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () => cubit.pickAndProcessCsv(),
          ),
          const SizedBox(height: AppConstants.space10),

          // Option 2: Download / View CSV Template
          OutlinedButton.icon(
            onPressed: () =>
                TimetableTemplateService.showTemplateSheet(context),
            icon: const Icon(Icons.file_download_outlined, size: 18),
            label: Text(l10n.downloadCsvTemplate),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.space12,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.space10),

          // Option 3: Manual Entry & Option 4: Try Another File
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => EditCandidateSheet.show(
                    context,
                    onSave: (newCandidate) => cubit.addCandidate(newCandidate),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.importAddLecture),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.space12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.space12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ImportSourceSheet.show(context),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Try Another File'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.space12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.space20),
        ],
      ),
    );
  }

  Widget _buildCandidatesListView(
    BuildContext context,
    ImportScheduleState state,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.space16),
      children: [
        // Subtitle instructions
        Text(
          l10n.importReviewSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: AppConstants.space12),

        // Summary KPI Metrics Bar
        _buildSummaryMetricsBar(state, l10n, theme),
        const SizedBox(height: AppConstants.space12),

        // Document Name Pill (if available)
        if (state.sourceFileName != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.space12,
              vertical: AppConstants.space6,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(AppConstants.radius8),
            ),
            child: Row(
              children: [
                Icon(
                  state.sourceFileName!.toLowerCase().endsWith('.pdf')
                      ? Icons.picture_as_pdf_outlined
                      : Icons.image_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppConstants.space8),
                Expanded(
                  child: Text(
                    state.sourceFileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.space12),
        ],

        // Candidates List
        ...state.candidates.map(
          (candidate) => Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.space12),
            child: CandidateLectureCard(
              candidate: candidate,
              onEdit: () => EditCandidateSheet.show(
                context,
                candidate: candidate,
                onSave: (updated) =>
                    cubit.updateCandidateById(candidate.id, updated),
              ),
              onDelete: () => cubit.removeCandidateById(candidate.id),
            ),
          ),
        ),

        const SizedBox(height: AppConstants.space8),

        // "+ Add Class" button inline
        OutlinedButton.icon(
          onPressed: () => EditCandidateSheet.show(
            context,
            onSave: (newCandidate) => cubit.addCandidate(newCandidate),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.importAddLecture),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppConstants.space12),
          ),
        ),
        const SizedBox(height: AppConstants.space32),
      ],
    );
  }

  Widget _buildSummaryMetricsBar(
    ImportScheduleState state,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // Ready
        Expanded(
          child: _MetricItem(
            count: state.validCount,
            label: 'Ready',
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: AppConstants.space8),

        // Incomplete
        if (state.invalidCount > 0) ...[
          Expanded(
            child: _MetricItem(
              count: state.invalidCount,
              label: 'Fix',
              color: AppColors.error,
            ),
          ),
          const SizedBox(width: AppConstants.space8),
        ],

        // Conflicts / Overlaps
        if (state.conflictCount > 0) ...[
          Expanded(
            child: _MetricItem(
              count: state.conflictCount,
              label: 'Overlap',
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppConstants.space8),
        ],

        // Duplicates
        if (state.duplicateCount > 0) ...[
          Expanded(
            child: _MetricItem(
              count: state.duplicateCount,
              label: 'Duplicate',
              color: AppColors.info,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ImportScheduleState state,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.space16),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
        ),
        child: AppButton(
          text: '${l10n.importConfirmButton} (${state.candidates.length})',
          icon: const Icon(
            Icons.download_done_rounded,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => _handleConfirmImport(context, state, cubit, l10n),
        ),
      ),
    );
  }

  void _handleConfirmImport(
    BuildContext context,
    ImportScheduleState state,
    ImportScheduleCubit cubit,
    AppLocalizations l10n,
  ) {
    // 1. Check if there are any invalid candidates (missing title, invalid time, etc.)
    if (state.invalidCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Incomplete Classes'),
          content: const Text(
            'Some extracted classes have missing course names or invalid time ranges. Please edit or remove them before importing.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.gotIt),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Check duplicates
    if (state.duplicateCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Duplicate Classes Found'),
          content: Text(
            '${state.duplicateCount} classes appear to already exist in your weekly schedule. Would you like to skip duplicates and import only new classes?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                cubit.confirmImport(skipDuplicates: true);
              },
              child: const Text('Skip Duplicates & Import'),
            ),
          ],
        ),
      );
      return;
    }

    // 3. Check conflicts
    if (state.conflictCount > 0) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Time Conflict Warning'),
          content: Text(
            '${state.conflictCount} classes overlap with other classes on the same weekday. Do you want to proceed and import them anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.close),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                cubit.confirmImport(skipDuplicates: false);
              },
              child: const Text('Import Anyway'),
            ),
          ],
        ),
      );
      return;
    }

    // 4. Everything clean, confirm import directly
    cubit.confirmImport(skipDuplicates: false);
  }
}

class _MetricItem extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _MetricItem({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.space8,
        vertical: AppConstants.space8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radius8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
