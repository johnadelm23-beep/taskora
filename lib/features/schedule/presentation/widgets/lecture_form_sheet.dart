import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/features/schedule/domain/entities/lecture_entity.dart';
import 'package:taskora/features/schedule/presentation/cubit/schedule_cubit.dart';

class LectureFormSheet extends StatefulWidget {
  final int initialDayIndex;
  final LectureEntity? lectureToEdit;

  const LectureFormSheet({
    super.key,
    required this.initialDayIndex,
    this.lectureToEdit,
  });

  static Future<void> show(
    BuildContext context, {
    int? initialDayIndex,
    LectureEntity? lectureToEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ScheduleCubit>(),
        child: LectureFormSheet(
          initialDayIndex: initialDayIndex ?? lectureToEdit?.dayOfWeek ?? 0,
          lectureToEdit: lectureToEdit,
        ),
      ),
    );
  }

  @override
  State<LectureFormSheet> createState() => _LectureFormSheetState();
}

class _LectureFormSheetState extends State<LectureFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseNameController;
  late final TextEditingController _courseCodeController;
  late final TextEditingController _roomController;
  late final TextEditingController _instructorController;
  late final TextEditingController _notesController;

  late int _selectedDayIndex;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _conflictWarning;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.lectureToEdit;

    _courseNameController = TextEditingController(text: edit?.courseName ?? '');
    _courseCodeController = TextEditingController(text: edit?.courseCode ?? '');
    _roomController = TextEditingController(text: edit?.room ?? '');
    _instructorController = TextEditingController(text: edit?.instructor ?? '');
    _notesController = TextEditingController(text: edit?.notes ?? '');

    _selectedDayIndex = edit?.dayOfWeek ?? widget.initialDayIndex;

    if (edit != null) {
      _startTime = _parseTime(edit.startTime);
      _endTime = _parseTime(edit.endTime);
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 30);
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _roomController.dispose();
    _instructorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.lectureToEdit != null;

    final days = [
      l10n.translate('day_sun'),
      l10n.translate('day_mon'),
      l10n.translate('day_tue'),
      l10n.translate('day_wed'),
      l10n.translate('day_thu'),
      l10n.translate('day_fri'),
      l10n.translate('day_sat'),
    ];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space20),
          child: Form(
            key: _formKey,
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
                const SizedBox(height: AppConstants.space16),

                // Sheet Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.space8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius8,
                        ),
                      ),
                      child: Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Text(
                      isEditing ? 'Edit Lecture' : l10n.addLecture,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space16),

                // Conflict Warning Banner (if any)
                if (_conflictWarning != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppConstants.space12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius12,
                      ),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        Expanded(
                          child: Text(
                            _conflictWarning!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.space16),
                ],

                // Course Name (Required)
                TextFormField(
                  controller: _courseNameController,
                  decoration: InputDecoration(
                    labelText: '${l10n.courseName} *',
                    hintText: 'e.g. Data Structures & Algorithms',
                    prefixIcon: const Icon(Icons.menu_book_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a course name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.space12),

                // Course Code & Room
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _courseCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code',
                          hintText: 'e.g. CS201',
                          prefixIcon: Icon(Icons.code_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Expanded(
                      child: TextFormField(
                        controller: _roomController,
                        decoration: InputDecoration(
                          labelText: l10n.location,
                          hintText: 'e.g. Hall 3B',
                          prefixIcon: const Icon(Icons.room_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space12),

                // Instructor
                TextFormField(
                  controller: _instructorController,
                  decoration: InputDecoration(
                    labelText: l10n.instructor,
                    hintText: 'e.g. Dr. Sarah Ahmed',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),

                // Day of Week
                Text(
                  'Weekday',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.space8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(days.length, (index) {
                      final isSelected = index == _selectedDayIndex;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppConstants.space8,
                        ),
                        child: ChoiceChip(
                          label: Text(days[index]),
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
                              setState(() {
                                _selectedDayIndex = index;
                                _conflictWarning = null;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),

                // Start & End Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: _buildTimePickerTile(
                        context,
                        label: 'Start Time',
                        time: _startTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _startTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _startTime = picked;
                              _conflictWarning = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Expanded(
                      child: _buildTimePickerTile(
                        context,
                        label: 'End Time',
                        time: _endTime,
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _endTime,
                          );
                          if (picked != null) {
                            setState(() {
                              _endTime = picked;
                              _conflictWarning = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space12),

                // Optional Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'e.g. Bring lab coat, project presentation',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.space24),

                // Submit Button
                AppButton(
                  text: isEditing ? 'Update Lecture' : l10n.addLecture,
                  isLoading: _isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile(
    BuildContext context, {
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.radius12),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.space12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppConstants.space4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppConstants.space8),
                Text(
                  timeStr,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final scheduleCubit = context.read<ScheduleCubit>();

    final startTimeStr =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    // Validation: End time must be later than start time
    if (endTimeStr.compareTo(startTimeStr) <= 0) {
      setState(() {
        _conflictWarning = 'End time must be later than start time.';
      });
      return;
    }

    final lecture = LectureEntity(
      id: widget.lectureToEdit?.id ?? 0,
      courseName: _courseNameController.text.trim(),
      courseCode: _courseCodeController.text.trim(),
      room: _roomController.text.trim(),
      instructor: _instructorController.text.trim(),
      dayOfWeek: _selectedDayIndex,
      startTime: startTimeStr,
      endTime: endTimeStr,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    // Overlap Check Validation
    final conflict = await scheduleCubit.checkConflict(lecture);
    if (!mounted) return;

    if (conflict != null) {
      setState(() {
        _conflictWarning =
            'Time conflict: Overlaps with "${conflict.courseName}" (${conflict.startTime} - ${conflict.endTime}) on this day.';
      });
      return;
    }

    setState(() => _isSaving = true);

    final success = widget.lectureToEdit != null
        ? await scheduleCubit.updateLecture(lecture)
        : await scheduleCubit.addLecture(lecture);

    if (!mounted) return;

    setState(() => _isSaving = false);
    if (success) {
      Navigator.of(context).pop();
    } else {
      final error = scheduleCubit.state.errorMessage;
      setState(() {
        _conflictWarning = error ?? 'Failed to save lecture';
      });
    }
  }
}
