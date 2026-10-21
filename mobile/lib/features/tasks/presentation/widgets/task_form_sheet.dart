import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/priority_badge.dart';
import '../../../calendar/domain/calendar_event.dart';
import '../../../calendar/presentation/calendar_controller.dart';
import '../../../habits/presentation/habits_controller.dart';
import '../../../reminders/presentation/reminders_controller.dart';
import '../../domain/task.dart';
import '../tasks_controller.dart';

/// S-06 Quick Add / Task Form Bottom Sheet — matches Google Stitch `Quick Add Task` (`a71488fb9bbb4369b67242342dbe17e9`).
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
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => TaskFormSheet(initialTask: initialTask),
    );
  }

  @override
  ConsumerState<TaskFormSheet> createState() => _TaskFormSheetState();
}

enum _QuickAddSegment { task, event, habit }

class _CategoryOption {
  const _CategoryOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _TaskFormSheetState extends ConsumerState<TaskFormSheet> {
  static const _categories = <_CategoryOption>[
    _CategoryOption('Academic', LucideIcons.graduationCap),
    _CategoryOption('Project', LucideIcons.laptop),
    _CategoryOption('Personal', LucideIcons.user),
    _CategoryOption('Organization', LucideIcons.users),
  ];

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  _QuickAddSegment _segment = _QuickAddSegment.task;
  late TaskPriority _priority;
  late TaskStatus _status;
  String _selectedCategory = 'Academic';
  bool _remindMe = true;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  String? _titleError;
  String? _reminderNotice;
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
    } else if (!_isEditing) {
      final now = DateTime.now();
      _dueDate = DateTime(now.year, now.month, now.day);
      _dueTime = const TimeOfDay(hour: 14, minute: 0);
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
        _dueTime ??= const TimeOfDay(hour: 14, minute: 0);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null && mounted) {
      setState(() {
        _dueTime = picked;
        final now = DateTime.now();
        _dueDate ??= DateTime(now.year, now.month, now.day);
      });
    }
  }

  String _formatDateChip() {
    if (_dueDate == null) return 'Select Date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = _dueDate!.difference(today).inDays;
    final monthDay = DateFormat('MMM d').format(_dueDate!);
    if (diff == 0) return 'Today, $monthDay';
    if (diff == 1) return 'Tomorrow, $monthDay';
    return DateFormat('EEE, MMM d').format(_dueDate!);
  }

  String _formatTimeChip(BuildContext context) {
    if (_dueTime == null) return 'Set time';
    final startH = _dueTime!.hour.toString().padLeft(2, '0');
    final startM = _dueTime!.minute.toString().padLeft(2, '0');
    return '$startH:$startM';
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
      _reminderNotice = null;
      _isSubmitting = true;
    });

    final description = _descriptionController.text.trim();
    final dueAt = _composeDueAt();
    final notifier = ref.read(tasksControllerProvider.notifier);

    try {
      if (_isEditing) {
        final saved = await notifier.updateTask(
          widget.initialTask!,
          title: title,
          description: description.isEmpty ? null : description,
          includeNullDescription: description.isEmpty,
          status: _status,
          priority: _priority,
          dueAt: dueAt,
          includeNullDueAt: dueAt == null,
        );
        await _syncTaskReminderSafely(saved);
      } else if (_segment == _QuickAddSegment.habit) {
        await ref.read(habitsControllerProvider.notifier).createHabit(
              name: title.length > 120 ? title.substring(0, 120) : title,
              description: description.isEmpty ? null : description,
            );
      } else if (_segment == _QuickAddSegment.event) {
        final start = dueAt ?? DateTime.now().add(const Duration(hours: 1));
        final end = start.add(const Duration(hours: 1));
        final savedEvent =
            await ref.read(calendarControllerProvider.notifier).createEvent(
                  title: title,
                  description: description.isEmpty ? null : description,
                  startsAt: start,
                  endsAt: end,
                );
        await _syncEventReminderSafely(savedEvent);
      } else {
        final saved = await notifier.createTask(
          title: title,
          description: description.isEmpty ? null : description,
          priority: _priority,
          dueAt: dueAt,
        );
        await _syncTaskReminderSafely(saved);
      }
      if (mounted) {
        final notice = _reminderNotice;
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop(true);
        if (notice != null) {
          messenger.showSnackBar(
            SnackBar(content: Text(notice), duration: const Duration(seconds: 4)),
          );
        }
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

  /// Keeps the reminder in sync after a task is created/updated without
  /// failing the already-persisted task (`03-technical-spec.md` §3.2).
  Future<void> _syncTaskReminderSafely(Task saved) async {
    final controller = ref.read(remindersControllerProvider.notifier);
    final dueAt = saved.dueAt;

    try {
      if (!_remindMe ||
          dueAt == null ||
          saved.status == TaskStatus.done) {
        await controller.cancelScheduledForTarget(taskId: saved.id);
        return;
      }

      final remindAt = dueAt.subtract(const Duration(minutes: 15));
      if (!remindAt.isAfter(DateTime.now())) {
        await controller.cancelScheduledForTarget(taskId: saved.id);
        _reminderNotice =
            'Task disimpan. Pengingat tidak dijadwalkan karena waktunya '
            'kurang dari 15 menit lagi.';
        return;
      }

      final result = await controller.upsertForTask(
        taskId: saved.id,
        title: saved.title,
        remindAt: remindAt,
      );
      if (result != null && !result.permissionGranted) {
        _reminderNotice =
            'Task disimpan, tetapi izin notifikasi nonaktif. Aktifkan di '
            'Pengaturan Android → Apps → LifeOS → Notifications.';
      }
    } on ApiException catch (error) {
      _reminderNotice = 'Task disimpan, tetapi pengingat gagal: '
          '${error.message}';
    }
  }

  /// Event-mode variant of `_syncTaskReminderSafely` for Quick Add → Event.
  Future<void> _syncEventReminderSafely(CalendarEvent saved) async {
    final controller = ref.read(remindersControllerProvider.notifier);

    try {
      if (!_remindMe) {
        await controller.cancelScheduledForTarget(eventId: saved.id);
        return;
      }

      final remindAt = saved.startsAt.subtract(const Duration(minutes: 15));
      if (!remindAt.isAfter(DateTime.now())) {
        await controller.cancelScheduledForTarget(eventId: saved.id);
        _reminderNotice =
            'Event disimpan. Pengingat tidak dijadwalkan karena waktunya '
            'kurang dari 15 menit lagi.';
        return;
      }

      final result = await controller.upsertForEvent(
        eventId: saved.id,
        title: saved.title,
        remindAt: remindAt,
      );
      if (result != null && !result.permissionGranted) {
        _reminderNotice =
            'Event disimpan, tetapi izin notifikasi nonaktif. Aktifkan di '
            'Pengaturan Android → Apps → LifeOS → Notifications.';
      }
    } on ApiException catch (error) {
      _reminderNotice = 'Event disimpan, tetapi pengingat gagal: '
          '${error.message}';
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
            // Drag Pill Indicator
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E8EF),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditing ? 'Edit Task' : 'Quick Add',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                    height: 28 / 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isEditing) ...[
                      IconButton(
                        tooltip: 'Delete task',
                        onPressed: _isSubmitting ? null : _delete,
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: AppColors.error,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => Navigator.of(context).pop(false),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mode Segment Control (Task / Event / Habit)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: [
                  _buildSegmentButton(
                    segment: _QuickAddSegment.task,
                    label: 'Task',
                    icon: LucideIcons.circleCheck,
                  ),
                  _buildSegmentButton(
                    segment: _QuickAddSegment.event,
                    label: 'Event',
                    icon: LucideIcons.calendar,
                  ),
                  _buildSegmentButton(
                    segment: _QuickAddSegment.habit,
                    label: 'Habit',
                    icon: LucideIcons.sparkles,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Title Input Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: _titleError != null
                    ? Border.all(color: AppColors.error, width: 1.2)
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.filePenLine,
                    size: 19,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.next,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Makalah Etika Profesi IT',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (_titleController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _titleController.clear();
                        setState(() {});
                      },
                      child: const Icon(
                        LucideIcons.circleX,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (_titleError != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _titleError!,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Description / Notes Field
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      LucideIcons.fileText,
                      size: 19,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: 2,
                      minLines: 2,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        height: 18 / 13,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add subtasks, links or room details...',
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Schedule Chips Row (Date & Time & Repeat)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.violetPastel,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDateChip(),
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.clock,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatTimeChip(context),
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    onTap: _dueDate != null
                        ? () => setState(() {
                              _dueDate = null;
                              _dueTime = null;
                            })
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.repeat,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Never',
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Priority Selector
            Text(
              'Priority',
              style: textTheme.titleSmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
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
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? fg : bg,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: fg.withValues(alpha: 0.28),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: selected ? Colors.white : fg,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              priority.label,
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white : fg,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Category Selector Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Category',
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '+ New Tag',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final selected = _selectedCategory == cat.label;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () => setState(() => _selectedCategory = cat.label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF413EDC)
                              : AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: selected
                              ? const [
                                  BoxShadow(
                                    color: Color(0x335B5BF6),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              cat.icon,
                              size: 15,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              cat.label,
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            // Remind me Toggle Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F3FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.skyPastel,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.bellRing,
                          size: 18,
                          color: AppColors.sky,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remind me',
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '15 minutes before due',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _remindMe = !_remindMe),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 48,
                      height: 28,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _remindMe
                            ? AppColors.primary
                            : const Color(0xFFE1E2E9),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      alignment: _remindMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _remindMe ? LucideIcons.check : LucideIcons.x,
                          size: 12,
                          color: _remindMe
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // Bottom Action Button ("Save Task")
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x595B5BF6),
                    blurRadius: 20,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing ? 'Update Task' : 'Save Task',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required _QuickAddSegment segment,
    required String label,
    required IconData icon,
  }) {
    final selected = _segment == segment;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _segment = segment),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x405B5BF6),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
