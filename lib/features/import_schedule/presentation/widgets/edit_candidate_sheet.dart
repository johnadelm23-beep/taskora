import 'package:flutter/material.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/features/import_schedule/domain/entities/extracted_lecture_candidate.dart';

class EditCandidateSheet extends StatefulWidget {
  final ExtractedLectureCandidate? candidate;
  final void Function(ExtractedLectureCandidate candidate) onSave;

  const EditCandidateSheet({super.key, this.candidate, required this.onSave});

  static Future<void> show(
    BuildContext context, {
    ExtractedLectureCandidate? candidate,
    required void Function(ExtractedLectureCandidate candidate) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => EditCandidateSheet(candidate: candidate, onSave: onSave),
    );
  }

  @override
  State<EditCandidateSheet> createState() => _EditCandidateSheetState();
}

class _EditCandidateSheetState extends State<EditCandidateSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _courseNameController;
  late final TextEditingController _courseCodeController;
  late final TextEditingController _roomController;
  late final TextEditingController _instructorController;
  late final TextEditingController _notesController;

  int? _selectedDayIndex;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _timeError;
  String? _dayError;

  bool get _isReversed {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    return endMinutes < startMinutes;
  }

  @override
  void initState() {
    super.initState();
    final c = widget.candidate;

    _courseNameController = TextEditingController(text: c?.courseName ?? '');
    _courseCodeController = TextEditingController(text: c?.courseCode ?? '');
    _roomController = TextEditingController(text: c?.room ?? '');
    _instructorController = TextEditingController(text: c?.instructor ?? '');
    _notesController = TextEditingController(text: c?.notes ?? '');

    if (c != null) {
      if (c.dayOfWeek != null && c.dayOfWeek! >= 0 && c.dayOfWeek! < 7) {
        _selectedDayIndex = c.dayOfWeek!;
      } else {
        _selectedDayIndex = null;
      }
    } else {
      _selectedDayIndex = 0;
    }

    if (c != null && c.startTime != null && c.endTime != null) {
      _startTime = _parseTime(c.startTime!, defaultHour: 9);
      _endTime = _parseTime(c.endTime!, defaultHour: 10, defaultMin: 30);
    } else {
      _startTime = const TimeOfDay(hour: 9, minute: 0);
      _endTime = const TimeOfDay(hour: 10, minute: 30);
    }
  }

  TimeOfDay _parseTime(
    String timeStr, {
    int defaultHour = 9,
    int defaultMin = 0,
  }) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (_) {}
    return TimeOfDay(hour: defaultHour, minute: defaultMin);
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

  void _submit() {
    setState(() {
      _timeError = null;
      _dayError = null;
    });

    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDayIndex == null) {
      setState(() {
        _dayError = l10n.importMissingDay;
      });
      return;
    }

    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;

    if (endMinutes <= startMinutes) {
      setState(() {
        _timeError = l10n.importInvalidTime;
      });
      return;
    }

    final startStr =
        '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

    final ExtractedLectureCandidate updated;
    if (widget.candidate != null) {
      updated = widget.candidate!.copyWith(
        courseName: _courseNameController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        room: _roomController.text.trim(),
        instructor: _instructorController.text.trim(),
        dayOfWeek: _selectedDayIndex,
        startTime: startStr,
        endTime: endStr,
        notes: _notesController.text.trim(),
      );
    } else {
      updated = ExtractedLectureCandidate(
        id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
        courseName: _courseNameController.text.trim(),
        courseCode: _courseCodeController.text.trim(),
        room: _roomController.text.trim(),
        instructor: _instructorController.text.trim(),
        dayOfWeek: _selectedDayIndex!,
        startTime: startStr,
        endTime: endStr,
        notes: _notesController.text.trim(),
      );
    }

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.candidate != null;

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
                      isEditing
                          ? l10n.importEditCandidate
                          : l10n.importAddLecture,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space16),

                // Time error banner
                if (_timeError != null) ...[
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
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        Expanded(
                          child: Text(
                            _timeError!,
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
                    hintText: 'e.g. Operating Systems / نظم التشغيل',
                    prefixIcon: const Icon(Icons.menu_book_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.importMissingTitle;
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
                          hintText: 'e.g. CS302',
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
                          hintText: 'e.g. Lab 4 / قاعة 101',
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
                    hintText: 'e.g. Dr. Ahmed / د. أحمد',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),

                // Weekday selection
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
                                _dayError = null;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ),
                ),
                if (_dayError != null) ...[
                  const SizedBox(height: AppConstants.space6),
                  Text(
                    _dayError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.space16),

                // Reversed time warning & swap helper
                if (_isReversed) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.space12,
                      vertical: AppConstants.space8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radius8),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: AppConstants.space8),
                        Expanded(
                          child: Text(
                            'End time is earlier than start time',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: AppColors.primary,
                          ),
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: const Text('Swap Times'),
                          onPressed: () {
                            setState(() {
                              final temp = _startTime;
                              _startTime = _endTime;
                              _endTime = temp;
                              _timeError = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.space12),
                ],

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
                              _timeError = null;
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
                              _timeError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: AppConstants.space6),
                  Text(
                    _timeError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: AppConstants.space12),

                // Notes (Optional)
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any extra details or section info...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: AppConstants.space20),

                // Save button
                AppButton(
                  text: l10n.importSaveChanges,
                  icon: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.space12,
          vertical: AppConstants.space12,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(AppConstants.radius12),
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
}
