import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme.dart';
import '../../features/tasks/domain/task.dart';
import 'priority_badge.dart';

/// Task card item matching Google Stitch `My Tasks` (`34ee994c09b04ed695ed6502cd4aebcc`).
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

    final metaText = _buildMetaText();
    final metaIcon = _resolveMetaIcon(isDone: isDone, isOverdue: isOverdue);

    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
                      width: 44,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 22,
                          height: 22,
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
                  child: Opacity(
                    opacity: isDone ? 0.6 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          task.title,
                          maxLines: 1,
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
                        if (metaText != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                metaIcon,
                                size: 13,
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  metaText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    height: 14 / 11,
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
                ),
                const SizedBox(width: 8),
                PriorityBadge(priority: task.priority),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _resolveMetaIcon({required bool isDone, required bool isOverdue}) {
    if (isDone) return LucideIcons.checkCheck;
    if (isOverdue) return LucideIcons.clockAlert;
    if (task.dueAt != null) {
      final local = task.dueAt!.toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(local.year, local.month, local.day);
      if (dueDay.difference(today).inDays > 0) {
        return LucideIcons.calendar;
      }
    }
    return LucideIcons.clock;
  }

  String? _buildMetaText() {
    final desc = (!compact && task.description != null && task.description!.trim().isNotEmpty)
        ? task.description!.trim()
        : null;

    if (task.isDone) {
      if (task.completedAt != null) {
        final local = task.completedAt!.toLocal();
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final doneDay = DateTime(local.year, local.month, local.day);
        final diff = doneDay.difference(today).inDays;
        if (diff == 0) return 'Done today';
        if (diff == -1) return 'Done yesterday';
        return 'Done ${DateFormat('d MMM').format(local)}';
      }
      return 'Done';
    }

    if (task.dueAt == null) {
      return desc;
    }

    final duePart = _formatDueMeta(task.dueAt!, task.isOverdue());
    if (desc != null) {
      return '$duePart · $desc';
    }
    return duePart;
  }

  static String _formatDueMeta(DateTime dueAtUtc, bool isOverdue) {
    final local = dueAtUtc.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(local.year, local.month, local.day);
    final diffDays = dueDay.difference(today).inDays;

    String dateLabel;
    if (diffDays == 0) {
      dateLabel = DateFormat('hh:mm a').format(local);
    } else if (diffDays == 1) {
      dateLabel = 'Tomorrow, ${DateFormat('HH:mm').format(local)}';
    } else if (diffDays == -1) {
      dateLabel = 'Yesterday, ${DateFormat('HH:mm').format(local)}';
    } else {
      dateLabel = '${DateFormat('d MMM').format(local)}, ${DateFormat('HH:mm').format(local)}';
    }

    return isOverdue ? 'Overdue · $dateLabel' : dateLabel;
  }
}
