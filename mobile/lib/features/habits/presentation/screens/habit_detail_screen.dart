import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../domain/habit.dart';
import '../habits_controller.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';

/// S-09 Habit Detail Screen (`DESIGN.md` Section 6 S-09 & `06-implementation-workflow-and-prompts.md` §6.4 #8):
/// - Current Streak (from API), Best Streak & Consistency % (computed client-side from `GET /habits/:id/logs`)
/// - Current month heatmap calendar (with interactive check-in / H-7 backfill)
/// - Active Days chip editor (updates `PATCH /habits/:id` without deleting history)
/// - Check-in log history (`logDate DESC`)
class HabitDetailScreen extends ConsumerStatefulWidget {
  const HabitDetailScreen({
    super.key,
    required this.initialHabit,
  });

  final Habit initialHabit;

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  static const _weekdayChips = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  bool _isUpdatingDays = false;

  Habit _resolveHabit() {
    final snapshot = ref.watch(habitsControllerProvider).value;
    if (snapshot != null) {
      for (final h in snapshot.items) {
        if (h.id == widget.initialHabit.id) {
          return h;
        }
      }
    }
    return widget.initialHabit;
  }

  Future<void> _toggleActiveWeekday(Habit habit, int day) async {
    if (_isUpdatingDays) return;
    final currentSet = {...habit.activeDays};
    if (currentSet.contains(day)) {
      if (currentSet.length <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('At least 1 active day is required.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      currentSet.remove(day);
    } else {
      currentSet.add(day);
    }

    final sortedDays = currentSet.toList()..sort();
    setState(() => _isUpdatingDays = true);
    HapticFeedback.lightImpact();

    try {
      await ref.read(habitsControllerProvider.notifier).updateHabit(
            habit,
            activeDays: sortedDays,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDays = false);
      }
    }
  }

  Future<void> _toggleDateCheckIn(
    Habit habit,
    String dateStr,
    bool currentlyCompleted,
  ) async {
    HapticFeedback.lightImpact();
    try {
      await ref.read(habitsControllerProvider.notifier).checkInForDate(
            habit,
            dateStr: dateStr,
            completed: !currentlyCompleted,
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final habit = _resolveHabit();
    final palette = HabitVisualPalette.forHabit(habit);
    final logsAsync = ref.watch(habitLogsProvider(habit.id));
    final logs = logsAsync.value ?? const <HabitLog>[];

    final now = DateTime.now();
    final bestStreak = habit.computeBestStreak(logs);
    final consistencyPct = habit.computeMonthlyConsistencyPercent(
      logs,
      now.year,
      now.month,
      now: now,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          habit.name,
          style: textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit Habit',
            icon: Icon(
              LucideIcons.pencil,
              size: 20,
              color: AppColors.textPrimary,
            ),
            onPressed: () async {
              await HabitFormSheet.show(context, existingHabit: habit);
              if (!context.mounted) return;
              final stillExists = ref
                      .read(habitsControllerProvider)
                      .value
                      ?.items
                      .any((h) => h.id == habit.id) ??
                  true;
              if (!stillExists) {
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Top Habit Summary Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: palette.pastelBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    palette.icon,
                    size: 26,
                    color: palette.accentColor,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (habit.description != null &&
                          habit.description!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          habit.description!,
                          style: textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Semantics(
                  label:
                      'Tandai kebiasaan ${habit.name} selesai hari ini',
                  checked: habit.completedToday,
                  button: true,
                  child: InkResponse(
                    onTap: () => _toggleDateCheckIn(
                      habit,
                      DateFormat('yyyy-MM-dd').format(now),
                      habit.completedToday,
                    ),
                    radius: 24,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: habit.completedToday
                                ? AppColors.success
                                : AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.check,
                            size: 20,
                            color: habit.completedToday
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 3 Stat Chips: Current Streak, Best Streak, Consistency %
          Row(
            children: [
              Expanded(
                child: _StatChipCard(
                  icon: LucideIcons.flame,
                  iconColor: AppColors.orange,
                  pastelBg: AppColors.orangePastel,
                  label: 'Current Streak',
                  value: '${habit.currentStreak} days',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChipCard(
                  icon: LucideIcons.trophy,
                  iconColor: AppColors.violet,
                  pastelBg: AppColors.violetPastel,
                  label: 'Best Streak',
                  value: '$bestStreak days',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChipCard(
                  icon: LucideIcons.target,
                  iconColor: AppColors.success,
                  pastelBg: AppColors.successPastel,
                  label: 'Consistency',
                  value: '$consistencyPct%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Active Days Chip Editor
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Days',
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${habit.activeDays.length} days/week',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _weekdayChips.map((entry) {
                    final day = entry.$1;
                    final label = entry.$2;
                    final isSelected = habit.activeDays.contains(day);
                    return Semantics(
                      label: 'Hari aktif $label',
                      selected: isSelected,
                      button: true,
                      child: GestureDetector(
                        onTap: () => _toggleActiveWeekday(habit, day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            label,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Current Month Heatmap Calendar
          _MonthHeatmapCard(
            habit: habit,
            logs: logs,
            now: now,
            accentColor: palette.accentColor,
            pastelBg: palette.pastelBg,
            onToggleDate: (dateStr, completed) =>
                _toggleDateCheckIn(habit, dateStr, completed),
          ),
          const SizedBox(height: 18),
          // Check-in History List
          Text(
            'Check-in History',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (logsAsync.isLoading && logs.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (logs.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'No check-in history yet. Tap the check button above to start your streak!',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            ...logs.take(14).map((log) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.successPastel,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.check,
                        size: 15,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log.logDate,
                        style: textTheme.titleSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (log.completedAt != null)
                      Text(
                        DateFormat('HH:mm').format(log.completedAt!),
                        style: textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatChipCard extends StatelessWidget {
  const _StatChipCard({
    required this.icon,
    required this.iconColor,
    required this.pastelBg,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color pastelBg;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: pastelBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeatmapCard extends StatelessWidget {
  const _MonthHeatmapCard({
    required this.habit,
    required this.logs,
    required this.now,
    required this.accentColor,
    required this.pastelBg,
    required this.onToggleDate,
  });

  final Habit habit;
  final List<HabitLog> logs;
  final DateTime now;
  final Color accentColor;
  final Color pastelBg;
  final void Function(String dateStr, bool currentlyCompleted) onToggleDate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final completedSet = logs.map((l) => l.logDate).toSet();
    final fmt = DateFormat('yyyy-MM-dd');
    final todayDate = DateTime(now.year, now.month, now.day);
    final earliestBackfill = todayDate.subtract(const Duration(days: 7));
    final firstOfMonth = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final leadingBlanks = firstOfMonth.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tap last 7 days to toggle',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map(
                  (d) => SizedBox(
                    width: 34,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemBuilder: (context, index) {
              if (index < leadingBlanks) {
                return const SizedBox.shrink();
              }
              final dayNum = index - leadingBlanks + 1;
              final date = DateTime(now.year, now.month, dayNum);
              final dateStr = fmt.format(date);
              final isCompleted = completedSet.contains(dateStr) ||
                  (date == todayDate && habit.completedToday);
              final isScheduled = habit.activeDays.contains(date.weekday);
              final isToday = date == todayDate;
              final canToggle = !date.isAfter(todayDate) &&
                  !date.isBefore(earliestBackfill);

              return GestureDetector(
                onTap: canToggle
                    ? () => onToggleDate(dateStr, isCompleted)
                    : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success
                        : (isScheduled
                            ? AppColors.surfaceMuted
                            : AppColors.surfaceMuted.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday
                        ? Border.all(color: AppColors.primary, width: 1.8)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isCompleted || isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isCompleted
                          ? Colors.white
                          : (isScheduled
                              ? AppColors.textPrimary
                              : AppColors.textSecondary.withValues(alpha: 0.45)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
