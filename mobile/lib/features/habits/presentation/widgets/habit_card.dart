import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../domain/habit.dart';

enum HabitCardVariant {
  fullWeeklyGrid,
  dashboardCompact,
}

class HabitVisualPalette {
  const HabitVisualPalette({
    required this.icon,
    required this.accentColor,
    required this.pastelBg,
  });

  final IconData icon;
  final Color accentColor;
  final Color pastelBg;

  static HabitVisualPalette forHabit(Habit habit) {
    final lower = habit.name.toLowerCase();
    if (lower.contains('air') ||
        lower.contains('minum') ||
        lower.contains('water') ||
        lower.contains('hydrat')) {
      return HabitVisualPalette(
        icon: LucideIcons.droplet,
        accentColor: AppColors.success,
        pastelBg: AppColors.successPastel,
      );
    }
    if (lower.contains('baca') ||
        lower.contains('buku') ||
        lower.contains('read') ||
        lower.contains('study') ||
        lower.contains('belajar')) {
      return HabitVisualPalette(
        icon: LucideIcons.bookOpen,
        accentColor: AppColors.violet,
        pastelBg: AppColors.violetPastel,
      );
    }
    if (lower.contains('lari') ||
        lower.contains('olahraga') ||
        lower.contains('workout') ||
        lower.contains('gym') ||
        lower.contains('run')) {
      return HabitVisualPalette(
        icon: LucideIcons.dumbbell,
        accentColor: AppColors.orange,
        pastelBg: AppColors.orangePastel,
      );
    }
    if (lower.contains('code') ||
        lower.contains('leetcode') ||
        lower.contains('koding') ||
        lower.contains('program')) {
      return HabitVisualPalette(
        icon: LucideIcons.terminal,
        accentColor: AppColors.sky,
        pastelBg: AppColors.skyPastel,
      );
    }

    final palettes = [
      HabitVisualPalette(
        icon: LucideIcons.flame,
        accentColor: AppColors.primary,
        pastelBg: AppColors.primarySoft,
      ),
      HabitVisualPalette(
        icon: LucideIcons.bookOpen,
        accentColor: AppColors.violet,
        pastelBg: AppColors.violetPastel,
      ),
      HabitVisualPalette(
        icon: LucideIcons.dumbbell,
        accentColor: AppColors.orange,
        pastelBg: AppColors.orangePastel,
      ),
      HabitVisualPalette(
        icon: LucideIcons.droplet,
        accentColor: AppColors.success,
        pastelBg: AppColors.successPastel,
      ),
    ];
    return palettes[habit.id.hashCode.abs() % palettes.length];
  }
}

/// Reusable `HabitCard` (`02-design-brief.md` Section 7 & `DESIGN.md` Section 6 S-08).
/// Wrapped in `RepaintBoundary` with lightweight shadows for 2GB RAM devices.
class HabitCard extends StatelessWidget {
  const HabitCard({
    super.key,
    required this.habit,
    required this.onToggleCheckIn,
    this.onTap,
    this.variant = HabitCardVariant.fullWeeklyGrid,
  });

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  final Habit habit;
  final VoidCallback onToggleCheckIn;
  final VoidCallback? onTap;
  final HabitCardVariant variant;

  List<WeeklyHabitLogItem> _resolvedWeeklyLogs() {
    if (habit.weeklyLogs.length == 7) {
      return habit.weeklyLogs;
    }
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final fmt = DateFormat('yyyy-MM-dd');
    final todayStr = fmt.format(now);
    return List.generate(7, (index) {
      final date = monday.add(Duration(days: index));
      final dateStr = fmt.format(date);
      final isoWeekday = index + 1;
      return WeeklyHabitLogItem(
        date: dateStr,
        isoWeekday: isoWeekday,
        scheduled: habit.activeDays.contains(isoWeekday),
        completed: dateStr == todayStr ? habit.completedToday : false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = HabitVisualPalette.forHabit(habit);
    final weekly = _resolvedWeeklyLogs();
    final scheduledCount = weekly.where((d) => d.scheduled).length;
    final denominator = scheduledCount == 0 ? 7 : scheduledCount;
    final completedCount = weekly.where((d) => d.completed).length;
    final fraction = (completedCount / denominator).clamp(0.0, 1.0);
    final percent = (fraction * 100).round();
    final todayWeekday = DateTime.now().weekday;

    return RepaintBoundary(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: palette.pastelBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        palette.icon,
                        size: 22,
                        color: palette.accentColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            habit.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orangePastel,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  '🔥 ${habit.currentStreak} day streak',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ),
                              Text(
                                '$completedCount/$denominator this week',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Semantics(
                      container: true,
                      label:
                          'Tandai kebiasaan ${habit.name} selesai hari ini',
                      checked: habit.completedToday,
                      button: true,
                      child: InkResponse(
                        key: ValueKey('habit_checkin_${habit.id}'),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          onToggleCheckIn();
                        },
                        radius: 24,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: habit.completedToday
                                    ? AppColors.success
                                    : AppColors.surfaceMuted,
                                shape: BoxShape.circle,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                                child: Icon(
                                  LucideIcons.check,
                                  key: ValueKey<bool>(habit.completedToday),
                                  size: 18,
                                  color: habit.completedToday
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (variant == HabitCardVariant.fullWeeklyGrid) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completedCount/$denominator completed this week',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$percent%',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: fraction),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedFraction, _) {
                        return LinearProgressIndicator(
                          value: animatedFraction,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            palette.accentColor,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Semantics(
                    label:
                        'Progres mingguan ${habit.name}: $completedCount dari $denominator hari terjadwal selesai',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final dayItem = weekly[i];
                        final isToday = dayItem.isoWeekday == todayWeekday;
                        final done = dayItem.completed;
                        final scheduled = dayItem.scheduled;

                        Color bgColor;
                        Border? border;
                        Color symbolColor;
                        String symbol;

                        if (done) {
                          bgColor = AppColors.success;
                          border = null;
                          symbolColor = Colors.white;
                          symbol = '✓';
                        } else if (scheduled) {
                          bgColor = Colors.transparent;
                          border = Border.all(
                            color: isToday
                                ? AppColors.primary
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.45),
                            width: 1.5,
                          );
                          symbolColor = isToday
                              ? AppColors.primary
                              : AppColors.textSecondary;
                          symbol = '';
                        } else {
                          bgColor =
                              AppColors.surfaceMuted.withValues(alpha: 0.55);
                          border = null;
                          symbolColor =
                              AppColors.textSecondary.withValues(alpha: 0.45);
                          symbol = '·';
                        }

                        return Column(
                          children: [
                            Text(
                              _dayLabels[i],
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight:
                                    isToday ? FontWeight.w700 : FontWeight.w500,
                                color: isToday
                                    ? AppColors.textPrimary
                                    : (scheduled
                                        ? AppColors.textSecondary
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.45)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              curve: Curves.easeOutCubic,
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: bgColor,
                                shape: BoxShape.circle,
                                border: border,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: symbolColor,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
