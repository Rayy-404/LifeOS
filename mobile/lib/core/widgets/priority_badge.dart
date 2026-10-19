import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../features/tasks/domain/task.dart';

/// Pastel priority pill (`DESIGN.md` Section 2 & S-05).
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({
    super.key,
    required this.priority,
  });

  final TaskPriority priority;

  static Color foregroundFor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.error;
      case TaskPriority.medium:
        return AppColors.warning;
      case TaskPriority.low:
        return AppColors.success;
    }
  }

  static Color backgroundFor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppColors.errorPastel;
      case TaskPriority.medium:
        return AppColors.warningPastel;
      case TaskPriority.low:
        return AppColors.successPastel;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = foregroundFor(priority);
    final bg = backgroundFor(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        priority.label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
      ),
    );
  }
}
