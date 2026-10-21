import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../calendar/presentation/calendar_controller.dart';
import '../../domain/calendar_event.dart';
import '../../../reminders/presentation/reminders_controller.dart';

/// Create / Edit Calendar Event Bottom Sheet (`DESIGN.md` S-07 & `06-implementation-workflow-and-prompts.md` §6.5 #6).
/// Enforces `endsAt > startsAt` on client and server.
class EventFormSheet extends ConsumerStatefulWidget {
  const EventFormSheet({
    super.key,
    this.existingEvent,
    this.initialDate,
  });

  final CalendarEvent? existingEvent;
  final DateTime? initialDate;

  static Future<CalendarEvent?> show(
    BuildContext context, {
    CalendarEvent? existingEvent,
    DateTime? initialDate,
  }) {
    return showModalBottomSheet<CalendarEvent>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EventFormSheet(
        existingEvent: existingEvent,
        initialDate: initialDate,
      ),
    );
  }

  @override
  ConsumerState<EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends ConsumerState<EventFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  bool _remindMe = true;
  String? _reminderNotice;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingEvent;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _locationController = TextEditingController(text: existing?.location ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');

    if (existing != null) {
      final start = existing.startsAt.toLocal();
      final end = existing.endsAt.toLocal();
      _selectedDate = DateTime(start.year, start.month, start.day);
      _startTime = TimeOfDay(hour: start.hour, minute: start.minute);
      _endTime = TimeOfDay(hour: end.hour, minute: end.minute);
    } else {
      final base = widget.initialDate ?? DateTime.now();
      _selectedDate = DateTime(base.year, base.month, base.day);
      final nextHour = (DateTime.now().hour + 1).clamp(8, 21);
      _startTime = TimeOfDay(hour: nextHour, minute: 0);
      _endTime = TimeOfDay(hour: (nextHour + 1).clamp(9, 23), minute: 0);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _composeDateTime(TimeOfDay time) {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _errorMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final startsAt = _composeDateTime(_startTime);
    final endsAt = _composeDateTime(_endTime);

    if (!endsAt.isAfter(startsAt)) {
      setState(() {
        _errorMessage = 'End time must be strictly after start time.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _reminderNotice = null;
    });

    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    final desc = _descriptionController.text.trim();
    final controller = ref.read(calendarControllerProvider.notifier);

    try {
      CalendarEvent saved;
      if (_isEditing) {
        saved = await controller.updateEvent(
          widget.existingEvent!,
          title: title,
          location: location.isEmpty ? null : location,
          includeNullLocation: location.isEmpty,
          description: desc.isEmpty ? null : desc,
          includeNullDescription: desc.isEmpty,
          startsAt: startsAt,
          endsAt: endsAt,
        );
      } else {
        saved = await controller.createEvent(
          title: title,
          location: location.isEmpty ? null : location,
          description: desc.isEmpty ? null : desc,
          startsAt: startsAt,
          endsAt: endsAt,
        );
      }

      await _syncReminderSafely(saved);

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final notice = _reminderNotice;
      Navigator.of(context).pop(saved);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            notice ?? (_isEditing ? 'Event updated' : 'Event created'),
          ),
          duration: Duration(seconds: notice == null ? 2 : 4),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save event. Please try again.';
      });
    }
  }

  /// Creates/moves/cancels the 15-minute local reminder for the saved event.
  /// Reminder failures never roll back the already-persisted event.
  Future<void> _syncReminderSafely(CalendarEvent saved) async {
    final reminders = ref.read(remindersControllerProvider.notifier);
    try {
      if (!_remindMe) {
        await reminders.cancelScheduledForTarget(eventId: saved.id);
        return;
      }

      final remindAt = saved.startsAt.subtract(const Duration(minutes: 15));
      if (!remindAt.isAfter(DateTime.now())) {
        await reminders.cancelScheduledForTarget(eventId: saved.id);
        _reminderNotice =
            'Event saved. Reminder not scheduled because the start time is '
            'less than 15 minutes away.';
        return;
      }

      final result = await reminders.upsertForEvent(
        eventId: saved.id,
        title: saved.title,
        remindAt: remindAt,
      );
      if (result != null && !result.permissionGranted) {
        _reminderNotice =
            'Event saved, but notification permission is off. Enable it in '
            'Android Settings → Apps → LifeOS → Notifications.';
      }
    } on ApiException catch (error) {
      _reminderNotice = 'Event saved, but the reminder failed: '
          '${error.message}';
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existingEvent;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Delete "${existing.title}" from your calendar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(calendarControllerProvider.notifier).deleteEvent(existing);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Event deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
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
                    _isEditing ? 'Edit Event' : 'Add Event',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _isSaving ? null : _confirmDelete,
                      tooltip: 'Delete event',
                      icon: const Icon(
                        LucideIcons.trash2,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  hintText: 'e.g. Operating Systems Lecture',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (v) {
                  final trimmed = v?.trim() ?? '';
                  if (trimmed.isEmpty) return 'Event title is required';
                  if (trimmed.length > 200) return 'Maximum 200 characters';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: 'Location (Optional)',
                  hintText: 'e.g. Bldg B · Room 204',
                  counterText: '',
                  prefixIcon: const Icon(LucideIcons.mapPin, size: 18),
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Date & Start/End Time Row
              Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('EEE, d MMM').format(_selectedDate),
                                style: textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _pickTime(isStart: true),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatTime(_startTime),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('–'),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: InkWell(
                      onTap: () => _pickTime(isStart: false),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_endTime),
                              style: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add agenda details or preparation notes',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(14),
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
                              '15 minutes before start',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _remindMe,
                      activeThumbColor: AppColors.primary,
                      onChanged: (value) => setState(() => _remindMe = value),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Save Changes' : 'Save Event',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
