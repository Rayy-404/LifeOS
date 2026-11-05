import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../calendar/presentation/calendar_controller.dart';
import '../../../tasks/presentation/tasks_controller.dart';
import '../reminders_controller.dart';

enum _ReminderTargetType { task, event, custom }

class ReminderFormSheet extends ConsumerStatefulWidget {
  const ReminderFormSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      builder: (_) => const ReminderFormSheet(),
    );
  }

  @override
  ConsumerState<ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<ReminderFormSheet> {
  _ReminderTargetType _targetType = _ReminderTargetType.custom;
  final TextEditingController _titleController = TextEditingController();

  String? _selectedTaskId;
  String? _selectedEventId;
  String? _selectedTitle;

  late DateTime _remindAt;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default to 1 hour from now, rounded to next 5 minutes
    final now = DateTime.now();
    _remindAt = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + 1,
      ((now.minute / 5).ceil() * 5) % 60,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _remindAt.isAfter(now) ? _remindAt : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_remindAt),
    );
    if (pickedTime == null || !mounted) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (!selected.isAfter(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih waktu di masa depan.')),
        );
      }
      return;
    }

    setState(() => _remindAt = selected);
  }

  void _applyPresetOffset(Duration offset) {
    setState(() {
      _remindAt = DateTime.now().add(offset);
    });
  }

  void _applyTomorrowMorning() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    setState(() {
      _remindAt = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0);
    });
  }

  Future<void> _submit() async {
    if (!mounted) return;
    if (!_remindAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waktu pengingat harus di masa depan.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? taskId = _selectedTaskId;
      String? eventId = _selectedEventId;
      String reminderTitle = '';

      if (_targetType == _ReminderTargetType.custom) {
        final title = _titleController.text.trim();
        if (title.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tulis judul pengingat terlebih dahulu.')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        // Create an underlying task so XOR contract is satisfied
        final createdTask = await ref
            .read(tasksControllerProvider.notifier)
            .createTask(title: title, dueAt: _remindAt);
        taskId = createdTask.id;
        reminderTitle = title;
      } else if (_targetType == _ReminderTargetType.task) {
        if (taskId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih tugas yang ingin diingatkan.')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        reminderTitle = _selectedTitle ?? 'Task Reminder';
      } else if (_targetType == _ReminderTargetType.event) {
        if (eventId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pilih kegiatan yang ingin diingatkan.')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        reminderTitle = _selectedTitle ?? 'Event Reminder';
      }

      final result = await ref
          .read(remindersControllerProvider.notifier)
          .createReminder(
            taskId: taskId,
            eventId: eventId,
            title: reminderTitle,
            body: 'Waktunya: $reminderTitle',
            remindAt: _remindAt,
          );

      if (!mounted) return;
      Navigator.of(context).pop();

      final formattedDate =
          DateFormat('EEEE, d MMM yyyy · HH:mm', 'id_ID').format(_remindAt);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.permissionGranted
                ? 'Pengingat dijadwalkan: $formattedDate'
                : 'Pengingat disimpan. Izin notifikasi dinonaktifkan di sistem.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pengingat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final tasks = ref.watch(tasksControllerProvider).value?.items ?? [];
    final activeTasks = tasks.where((t) => !t.isDone).toList();

    final calendarSnapshot =
        ref.watch(calendarControllerProvider).value;
    final upcomingEvents = calendarSnapshot?.events ?? [];

    final dateFormatted =
        DateFormat('EEEE, d MMMM yyyy · HH:mm', 'id_ID').format(_remindAt);

    return Padding(
      padding: EdgeInsets.only(
        bottom: mediaQuery.viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.bellPlus, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Tambah Pengingat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Tautkan Ke',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TargetTypeChip(
                  label: 'Catatan Baru',
                  icon: LucideIcons.penLine,
                  selected: _targetType == _ReminderTargetType.custom,
                  onTap: () => setState(() => _targetType = _ReminderTargetType.custom),
                ),
                const SizedBox(width: 8),
                _TargetTypeChip(
                  label: 'Tugas',
                  icon: LucideIcons.squareCheckBig,
                  selected: _targetType == _ReminderTargetType.task,
                  onTap: () => setState(() => _targetType = _ReminderTargetType.task),
                ),
                const SizedBox(width: 8),
                _TargetTypeChip(
                  label: 'Kegiatan',
                  icon: LucideIcons.calendar,
                  selected: _targetType == _ReminderTargetType.event,
                  onTap: () => setState(() => _targetType = _ReminderTargetType.event),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_targetType == _ReminderTargetType.custom) ...[
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Judul Pengingat',
                  hintText: 'Contoh: Kuis Matematika, Ambil Buku',
                  prefixIcon: Icon(LucideIcons.bell, size: 18),
                ),
              ),
            ] else if (_targetType == _ReminderTargetType.task) ...[
              if (activeTasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Belum ada tugas aktif. Gunakan opsi "Catatan Baru" di atas untuk membuat pengingat langsung.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedTaskId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Tugas',
                    prefixIcon: Icon(LucideIcons.listTodo, size: 18),
                  ),
                  items: activeTasks.map((t) {
                    return DropdownMenuItem<String>(
                      value: t.id,
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    final t = activeTasks.firstWhere((item) => item.id == id);
                    setState(() {
                      _selectedTaskId = id;
                      _selectedTitle = t.title;
                      if (t.dueAt != null && t.dueAt!.isAfter(DateTime.now())) {
                        _remindAt = t.dueAt!;
                      }
                    });
                  },
                ),
            ] else ...[
              if (upcomingEvents.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Belum ada kegiatan di kalender. Gunakan opsi "Catatan Baru" di atas untuk membuat pengingat langsung.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: _selectedEventId,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Kegiatan',
                    prefixIcon: Icon(LucideIcons.calendar, size: 18),
                  ),
                  items: upcomingEvents.map((e) {
                    return DropdownMenuItem<String>(
                      value: e.id,
                      child: Text(
                        e.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (id) {
                    final e = upcomingEvents.firstWhere((item) => item.id == id);
                    setState(() {
                      _selectedEventId = id;
                      _selectedTitle = e.title;
                      if (e.startsAt.isAfter(DateTime.now())) {
                        _remindAt = e.startsAt;
                      }
                    });
                  },
                ),
            ],
            const SizedBox(height: 18),
            Text(
              'Waktu Pengingat',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: '+15m',
                  onTap: () => _applyPresetOffset(const Duration(minutes: 15)),
                ),
                _PresetChip(
                  label: '+30m',
                  onTap: () => _applyPresetOffset(const Duration(minutes: 30)),
                ),
                _PresetChip(
                  label: '+1 jam',
                  onTap: () => _applyPresetOffset(const Duration(hours: 1)),
                ),
                _PresetChip(
                  label: 'Besok 08:00',
                  onTap: _applyTomorrowMorning,
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.clock, size: 18, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Icon(LucideIcons.pencil, size: 16, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Jadwalkan Pengingat',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _TargetTypeChip extends StatelessWidget {
  const _TargetTypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
