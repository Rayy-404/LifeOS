import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/habit.dart';
import '../habits_controller.dart';

/// Create / Edit Habit Bottom Sheet (`DESIGN.md` S-08 / S-09).
class HabitFormSheet extends ConsumerStatefulWidget {
  const HabitFormSheet({
    super.key,
    this.existingHabit,
  });

  final Habit? existingHabit;

  static Future<Habit?> show(
    BuildContext context, {
    Habit? existingHabit,
  }) {
    return showModalBottomSheet<Habit>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitFormSheet(existingHabit: existingHabit),
    );
  }

  @override
  ConsumerState<HabitFormSheet> createState() => _HabitFormSheetState();
}

class _HabitFormSheetState extends ConsumerState<HabitFormSheet> {
  static const _weekdayNames = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late Set<int> _selectedDays;
  late bool _isActive;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingHabit != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingHabit;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _selectedDays = {...(existing?.activeDays ?? const [1, 2, 3, 4, 5, 6, 7])};
    _isActive = existing?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleDay(int day) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(day)) {
        if (_selectedDays.length > 1) {
          _selectedDays.remove(day);
        } else {
          _errorMessage = 'Select at least 1 active day.';
        }
      } else {
        _selectedDays.add(day);
        _errorMessage = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDays.isEmpty) {
      setState(() => _errorMessage = 'Select at least 1 active day.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();

    final sortedDays = _selectedDays.toList()..sort();
    final trimmedName = _nameController.text.trim();
    final trimmedDesc = _descriptionController.text.trim();
    final controller = ref.read(habitsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);
    final isEditing = _isEditing;
    final existing = widget.existingHabit;
    final isActive = _isActive;

    final now = DateTime.now();
    final optimisticHabit = isEditing && existing != null
        ? existing.copyWith(
            name: trimmedName,
            description: trimmedDesc.isEmpty ? null : trimmedDesc,
            clearDescription: trimmedDesc.isEmpty,
            activeDays: sortedDays,
            isActive: isActive,
            updatedAt: now,
          )
        : Habit(
            id: 'temp_habit_${now.microsecondsSinceEpoch}',
            name: trimmedName,
            description: trimmedDesc.isEmpty ? null : trimmedDesc,
            isActive: true,
            activeDays: sortedDays,
            createdAt: now,
            updatedAt: now,
          );

    Future<void> backgroundWork() async {
      try {
        if (isEditing && existing != null) {
          await controller.updateHabit(
            existing,
            name: trimmedName,
            description: trimmedDesc.isEmpty ? null : trimmedDesc,
            includeNullDescription: trimmedDesc.isEmpty,
            activeDays: sortedDays,
            isActive: isActive,
          );
        } else {
          await controller.createHabit(
            name: trimmedName,
            description: trimmedDesc.isEmpty ? null : trimmedDesc,
            activeDays: sortedDays,
          );
        }
      } on ApiException catch (e) {
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan habit: ${e.message}'),
          ),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Gagal menyimpan habit. Coba lagi.'),
          ),
        );
      }
    }

    unawaited(backgroundWork());
    if (mounted) {
      Navigator.of(context).pop(optimisticHabit);
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Habit updated' : 'Habit created'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final existing = widget.existingHabit;
    if (existing == null || _isSaving) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit?'),
        content: Text(
          'Are you sure you want to delete "${existing.name}" and its check-in history?',
        ),
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
    HapticFeedback.mediumImpact();
    final controller = ref.read(habitsControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    unawaited(
      controller.deleteHabit(existing.id).catchError((Object e) {
        final msg = e is ApiException ? e.message : 'Gagal menghapus habit.';
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(msg),
          ),
        );
      }),
    );

    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Habit deleted'),
        duration: Duration(seconds: 2),
      ),
    );
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
                    _isEditing ? 'Edit Habit' : 'New Habit',
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      onPressed: _isSaving ? null : _confirmDelete,
                      tooltip: 'Delete habit',
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
                controller: _nameController,
                textInputAction: TextInputAction.next,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  hintText: 'e.g. Read 20 pages, Drink 2L water',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Habit name is required';
                  }
                  if (trimmed.length > 120) {
                    return 'Maximum 120 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Why or when do you practice this habit?',
                  filled: true,
                  fillColor: AppColors.surfaceMuted,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Days',
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDays = {1, 2, 3, 4, 5, 6, 7};
                        _errorMessage = null;
                      });
                    },
                    child: const Text('Every Day'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _weekdayNames.map((entry) {
                  final day = entry.$1;
                  final label = entry.$2;
                  final selected = _selectedDays.contains(day);
                  return GestureDetector(
                    onTap: () => _toggleDay(day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOutCubic,
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: textTheme.labelMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_isEditing) ...[
                const SizedBox(height: 14),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Active Habit',
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Scheduled in daily dashboard targets',
                    style: textTheme.bodySmall,
                  ),
                  value: _isActive,
                  activeTrackColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
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
                  child: Text(
                    _isEditing ? 'Save Changes' : 'Save Habit',
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
