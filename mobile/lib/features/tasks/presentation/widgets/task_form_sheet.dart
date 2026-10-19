import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../domain/task.dart';
import '../tasks_controller.dart';

/// S-06 Quick Add / Task Form Bottom Sheet (`DESIGN.md` S-06).
class TaskFormSheet extends ConsumerStatefulWidget {
  const TaskFormSheet({
    super.key,
    this.initialTask,
  });

  final Task? initialTask;

  static Future<bool?> show(
    BuildContext context, {
    Task? initialTask,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TaskFormSheet(initialTask: initialTask),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskPriority _priority;
  late TaskStatus _status;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _titleError;
  bool _isSubmitting = false;

  bool get _isEditing => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController =
        TextEditingController(text: task?.description ?? '');
    _priority = task?.priority ?? TaskPriority.medium;
    _status = task?.status ?? TaskStatus.todo;

    if (task?.dueAt != null) {
      final local = task!.dueAt!.toLocal();
      _dueDate = DateTime(local.year, local.month, local.day);
      _dueTime = TimeOfDay(hour: local.hour, minute: local.minute);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime? _composeDueAt() {
    if (_dueDate == null) return null;
    final time = _dueTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueDate = picked;
        _dueTime ??= const TimeOfDay(hour: 12, minute: 0);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueTime = picked;
        final now = DateTime.now();
        _dueDate ??= DateTime(now.year, now.month, now.day);
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'Judul tugas wajib diisi');
      return;
    }
    if (title.length > 200) {
      setState(() => _titleError = 'Judul maksimal 200 karakter');
      return;
    }

    setState(() {
      _titleError = null;
      _isSubmitting = true;
    });

    final description = _descriptionController.text.trim();
    final dueAt = _composeDueAt();
    final notifier = ref.read(tasksControllerProvider.notifier);

    try {
      if (_isEditing) {
        await notifier.updateTask(
          widget.initialTask!,
          title: title,
          description: description.isEmpty ? null : description,
          includeNullDescription: description.isEmpty,
          status: _status,
          priority: _priority,
          dueAt: dueAt,
          includeNullDueAt: dueAt == null,
        );
      } else {
        await notifier.createTask(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _priority,
          dueAt: dueAt,
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      final titleErr = error.details['title']?.firstOrNull;
      if (titleErr != null) {
        setState(() => _titleError = titleErr);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _delete() async {
    final task = widget.initialTask;
    if (task == null) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(tasksControllerProvider.notifier).deleteTask(task);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Task' : 'New Task',
                  style: textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    tooltip: 'Delete task',
                    onPressed: _isSubmitting ? null : _delete,
                    icon: const Icon(
                      LucideIcons.trash2,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                errorText: _titleError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add description or notes (optional)...',
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Due Date & Time',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _dueDate != null
                        ? DateFormat('EEE, d MMM yyyy').format(_dueDate!)
                        : 'Select Date',
                  ),
                  onPressed: _pickDate,
                ),
                ActionChip(
                  avatar: const Icon(
                    LucideIcons.clock,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _dueTime != null
                        ? _dueTime!.format(context)
                        : 'Select Time',
                  ),
                  onPressed: _pickTime,
                ),
                if (_dueDate != null)
                  ActionChip(
                    avatar: const Icon(
                      LucideIcons.x,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    label: const Text('Clear'),
                    onPressed: () => setState(() {
                      _dueDate = null;
                      _dueTime = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Priority',
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: TaskPriority.values.map((priority) {
                final selected = _priority == priority;
                final fg = PriorityBadge.foregroundFor(priority);
                final bg = PriorityBadge.backgroundFor(priority);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: priority != TaskPriority.high ? 8 : 0,
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => setState(() => _priority = priority),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? bg : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: selected ? fg : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            priority.label,
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selected ? fg : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 16),
              Text(
                'Status',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskStatus.values.map((status) {
                  final selected = _status == status;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: status != TaskStatus.done ? 8 : 0,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => setState(() => _status = status),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primarySoft
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              status.label,
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Text(_isEditing ? 'Update Task' : 'Save Task'),
            ),
          ],
        ),
      ),
    );
  }
}
