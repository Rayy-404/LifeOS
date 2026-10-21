import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../statistics/domain/statistics.dart';

class WeeklyTrendChartCard extends StatelessWidget {
  const WeeklyTrendChartCard({
    super.key,
    required this.weekly,
    required this.selectedTab,
  });

  final WeeklyStatistics weekly;
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final days = weekly.days;
    final showHabits = selectedTab == 2;
    final maxValue = days.fold<int>(
      1,
      (current, day) => math.max(
        current,
        showHabits
            ? math.max(day.habitsScheduled, day.habitsCompleted)
            : day.tasksCompleted,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5B5BF6),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                showHabits ? 'Habit Check-ins' : 'Task Completion',
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'This Week',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: days.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
                    BarChartData(
                      maxY: (maxValue + 1).toDouble(),
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= days.length) {
                                return const SizedBox.shrink();
                              }
                              const labels = [
                                'Mon',
                                'Tue',
                                'Wed',
                                'Thu',
                                'Fri',
                                'Sat',
                                'Sun',
                              ];
                              final label =
                                  labels[days[index].isoWeekday - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var index = 0; index < days.length; index++)
                          BarChartGroupData(
                            x: index,
                            barsSpace: 2,
                            barRods: showHabits
                                ? [
                                    BarChartRodData(
                                      toY:
                                          days[index].habitsScheduled.toDouble(),
                                      width: 7,
                                      color: AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    BarChartRodData(
                                      toY:
                                          days[index].habitsCompleted.toDouble(),
                                      width: 7,
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ]
                                : [
                                    BarChartRodData(
                                      toY:
                                          days[index].tasksCompleted.toDouble(),
                                      width: 12,
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                          ),
                      ],
                    ),
                  ),
          ),
          if (showHabits) ...[
            const SizedBox(height: 8),
            Row(
              children: const [
                LegendDot(color: AppColors.primary, label: 'Completed'),
                SizedBox(width: 14),
                LegendDot(color: AppColors.primarySoft, label: 'Scheduled'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  const LegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
