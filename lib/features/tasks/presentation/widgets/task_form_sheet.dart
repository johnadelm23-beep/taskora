import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:taskora/app/localization/app_localizations.dart';
import 'package:taskora/app/theme/app_colors.dart';
import 'package:taskora/core/utils/app_constants.dart';
import 'package:taskora/core/widgets/app_button.dart';
import 'package:taskora/features/tasks/domain/entities/task_entity.dart';
import 'package:taskora/features/tasks/presentation/cubit/task_cubit.dart';

class TaskFormSheet extends StatefulWidget {
  final TaskEntity? taskToEdit;

  const TaskFormSheet({super.key, this.taskToEdit});

  static Future<void> show(BuildContext context, {TaskEntity? taskToEdit}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radius24),
        ),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<TaskCubit>(),
        child: TaskFormSheet(taskToEdit: taskToEdit),
      ),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _courseController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.taskToEdit;

    _titleController = TextEditingController(text: edit?.title ?? '');
    _courseController = TextEditingController(text: edit?.courseName ?? '');
    _descriptionController = TextEditingController(
      text: edit?.description ?? '',
    );

    if (edit?.dueDate != null) {
      final local = edit!.dueDate!.toLocal();
      _selectedDate = DateTime(local.year, local.month, local.day);
      _selectedTime = TimeOfDay(hour: local.hour, minute: local.minute);
    } else {
      // Default: Tomorrow at 23:59
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      _selectedTime = const TimeOfDay(hour: 23, minute: 59);
    }

    _selectedPriority = edit?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _courseController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = _selectedDate.isBefore(now) ? now : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final dueDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final cubit = context.read<TaskCubit>();
    final isEdit = widget.taskToEdit != null;

    bool success;
    if (isEdit) {
      final updated = widget.taskToEdit!.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        courseName: _courseController.text.trim(),
        dueDate: dueDateTime,
        priority: _selectedPriority,
      );
      success = await cubit.updateTask(updated);
    } else {
      success = await cubit.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        courseName: _courseController.text.trim(),
        dueDate: dueDateTime,
        priority: _selectedPriority,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isSaving = false);
      final error = cubit.state.errorMessage ?? 'Failed to save task';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.taskToEdit != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(_selectedDate);
    final formattedTime = _selectedTime.format(context);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.space24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle indicator
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
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12,
                        ),
                      ),
                      child: Icon(
                        isEdit
                            ? Icons.edit_note_rounded
                            : Icons.add_task_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),
                    Expanded(
                      child: Text(
                        isEdit ? l10n.editTask : l10n.addTask,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space20),

                // Task Title
                TextFormField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.taskTitleLabel,
                    hintText: l10n.taskTitleHint,
                    prefixIcon: const Icon(Icons.title_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius12,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.taskTitleRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.space16),

                // Course Name (Optional)
                TextFormField(
                  controller: _courseController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.taskCourseLabel,
                    hintText: l10n.taskCourseHint,
                    prefixIcon: const Icon(Icons.school_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space16),

                // Description (Optional)
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: l10n.taskDescLabel,
                    hintText: l10n.taskDescHint,
                    prefixIcon: const Icon(Icons.notes_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.radius12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space20),

                // Due Date & Time Pickers Row
                Row(
                  children: [
                    // Date Button
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12,
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.dueDateLabel,
                            prefixIcon: const Icon(
                              Icons.calendar_today_rounded,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radius12,
                              ),
                            ),
                          ),
                          child: Text(
                            formattedDate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.space12),

                    // Time Button
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _pickTime(context),
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12,
                        ),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.dueTimeLabel,
                            prefixIcon: const Icon(Icons.access_time_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.radius12,
                              ),
                            ),
                          ),
                          child: Text(
                            formattedTime,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.space20),

                // Priority Selector
                Text(
                  l10n.priorityMedium
                      .split(' ')
                      .first, // 'Priority' / 'الأولوية'
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.space8),
                SegmentedButton<TaskPriority>(
                  segments: [
                    ButtonSegment(
                      value: TaskPriority.low,
                      label: Text(l10n.filterLow),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: TaskPriority.medium,
                      label: Text(l10n.filterMedium),
                      icon: const Icon(Icons.flag_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: TaskPriority.high,
                      label: Text(l10n.filterHigh),
                      icon: const Icon(Icons.tour_rounded, size: 16),
                    ),
                  ],
                  selected: {_selectedPriority},
                  onSelectionChanged: (set) {
                    setState(() => _selectedPriority = set.first);
                  },
                  style: ButtonStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radius12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.space24),

                // Submit Button
                AppButton(
                  text: isEdit ? l10n.updateTask : l10n.saveTask,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _handleSave,
                ),
                const SizedBox(height: AppConstants.space12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
