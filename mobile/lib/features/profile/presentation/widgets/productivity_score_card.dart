import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../statistics/domain/statistics.dart';

class ProductivityScoreCard extends StatelessWidget {
  const ProductivityScoreCard({
    super.key,
    required this.statistics,
    required this.selectedTab,
  });

  final StatisticsBundle statistics;
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final metrics = selectedTab == 2
        ? statistics.currentWeek.habits.consistencyRate
        : statistics.currentWeek.tasks.completionRate;
    final title = selectedTab == 2 ? 'Habit Consistency' : 'Productivity Score';
    final delta = statistics.completionDelta;
    final hasPreviousData = statistics.previousWeek.tasks.total > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: (metrics / 100).clamp(0, 1),
                    strokeWidth: 7,
                    backgroundColor: AppColors.primarySoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${metrics.round()}%',
                  style: textTheme.headlineMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                if (hasPreviousData)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: delta >= 0
                          ? AppColors.successPastel
                          : AppColors.errorPastel,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          delta >= 0
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 12,
                          color: delta >= 0
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${delta.abs().toStringAsFixed(1)}% vs last week',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: delta >= 0
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  selectedTab == 2
                      ? '${statistics.currentWeek.habits.totalCompletedInstances} of '
                          '${statistics.currentWeek.habits.totalScheduledInstances} '
                          'scheduled check-ins'
                      : '${statistics.currentWeek.tasks.completed} of '
                          '${statistics.currentWeek.tasks.total} tasks completed',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
