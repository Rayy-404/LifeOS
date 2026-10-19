import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme.dart';
import '../../features/tasks/domain/task.dart';
import 'priority_badge.dart';

/// Task card item (`DESIGN.md` S-05 & `02-design-brief.md` Section 7).
/// Supports one-tap completion with priority-colored circular checkbox and 48x48dp touch target.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggleDone,
    this.onTap,
    this.compact = false,
  });

  final Task task;
  final VoidCallback onToggleDone;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDone = task.isDone;
    final isOverdue = task.isOverdue();
    final ringColor = isDone
        ? AppColors.success
        : PriorityBadge.foregroundFor(task.priority);

    return Opacity(
      opacity: isDone ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F5B5BF6),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Semantics(
                    container: true,
                    label: 'Tandai tugas ${task.title} selesai',
                    checked: isDone,
                    button: true,
                    child: InkWell(
                      key: ValueKey('task_checkbox_${task.id}'),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggleDone();
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? AppColors.success
                                  : Colors.transparent,
                              border: Border.all(
                                color: ringColor,
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(
                                    LucideIcons.check,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        if (!compact &&
                            task.description != null &&
                            task.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (task.dueAt != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isOverdue
                                    ? LucideIcons.clockAlert
                                    : LucideIcons.clock,
                                size: 13,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _formatDueMeta(task.dueAt!, isOverdue),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: isOverdue
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PriorityBadge(priority: task.priority),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDueMeta(DateTime dueAtUtc, bool isOverdue) {
    final local = dueAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(local.year, local.month, local.day);
    final timeStr = DateFormat('HH:mm').format(local);

    String dateLabel;
    final diffDays = dueDay.difference(today).inDays;
    if (diffDays == 0) {
      dateLabel = 'Today, $timeStr';
    } else if (diffDays == 1) {
      dateLabel = 'Tomorrow, $timeStr';
    } else if (diffDays == -1) {
      dateLabel = 'Yesterday, $timeStr';
    } else {
      dateLabel = '${DateFormat('d MMM').format(local)}, $timeStr';
    }

    return isOverdue ? 'Overdue · $dateLabel' : dateLabel;
  }
}
