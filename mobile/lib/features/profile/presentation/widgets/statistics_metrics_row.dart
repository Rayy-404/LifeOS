import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../statistics/domain/statistics.dart';

class StatisticsMetricsRow extends StatelessWidget {
  const StatisticsMetricsRow({
    super.key,
    required this.statistics,
    required this.selectedTab,
  });

  final StatisticsBundle statistics;
  final int selectedTab;

  @override
  Widget build(BuildContext context) {
    final tasks = statistics.currentWeek.tasks;
    final habits = statistics.currentWeek.habits;

    final items = switch (selectedTab) {
      1 => [
          MetricData('Completed', '${tasks.completed}', AppColors.success),
          MetricData('Overdue', '${tasks.overdue}', AppColors.error),
          MetricData('Total', '${tasks.total}', AppColors.primary),
        ],
      2 => [
          MetricData(
            'Completed',
            '${habits.totalCompletedInstances}',
            AppColors.success,
          ),
          MetricData(
            'Scheduled',
            '${habits.totalScheduledInstances}',
            AppColors.primary,
          ),
          MetricData(
            'Consistency',
            '${habits.consistencyRate.toStringAsFixed(1)}%',
            AppColors.violet,
          ),
        ],
      _ => [
          MetricData('Tasks Done', '${tasks.completed}', AppColors.success),
          MetricData('Overdue', '${tasks.overdue}', AppColors.error),
          MetricData(
            'Habit Rate',
            '${habits.consistencyRate.toStringAsFixed(1)}%',
            AppColors.violet,
          ),
        ],
    };

    return Row(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 10),
          Expanded(child: MetricCard(data: items[index])),
        ],
      ],
    );
  }
}

class MetricData {
  const MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.data});

  final MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5B5BF6),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: data.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
