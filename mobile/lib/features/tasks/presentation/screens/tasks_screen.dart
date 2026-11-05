import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../core/widgets/task_card.dart';
import '../../domain/task.dart';
import '../tasks_controller.dart';
import '../widgets/task_form_sheet.dart';

/// S-05 My Tasks Screen — matches Google Stitch `My Tasks` (`34ee994c09b04ed695ed6502cd4aebcc`).
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      ref.read(tasksFilterProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openTaskForm({Task? task}) async {
    final saved = await TaskFormSheet.show(context, initialTask: task);
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(
            task == null ? 'Task created' : 'Task updated',
          ),
        ),
      );
    }
  }

  Future<void> _handleToggleDone(Task task) async {
    try {
      await ref.read(tasksControllerProvider.notifier).toggleTaskDone(task);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(tasksFilterProvider);
    final tasksAsync = ref.watch(tasksControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    final paginatedData = tasksAsync.value;
    final items = paginatedData?.items ?? const <Task>[];
    final totalCount = items.length;
    final completedCount = items.where((t) => t.isDone).length;
    final pendingCount = totalCount - completedCount;
    final progressRatio = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LifeOsTopHeader(title: 'Tasks'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  // Top Action Line with Dynamic Stats Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'My Tasks',
                            style: textTheme.headlineMedium?.copyWith(
                              fontSize: 22,
                              height: 28 / 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              key: ValueKey<int>(pendingCount),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                '$pendingCount Left',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        onTap: () => context.go(AppRoutes.profile),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.trendingUp,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Stats',
                                style: textTheme.labelMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search Input & Filter Tune Button Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceMuted,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search tasks...',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              prefixIcon: Icon(
                                LucideIcons.search,
                                size: 19,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        LucideIcons.x,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                        ref
                                            .read(tasksFilterProvider.notifier)
                                            .setSearch('');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.input),
                          border: Border.all(color: AppColors.border, width: 1),
                          boxShadow: AppShadows.card,
                        ),
                        child: PopupMenuButton<TaskPriority?>(
                          tooltip: 'Filter tasks',
                          icon: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                LucideIcons.slidersHorizontal,
                                size: 20,
                                color: filter.priority != null
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                              if (filter.priority != null)
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onSelected: (priority) => ref
                              .read(tasksFilterProvider.notifier)
                              .setPriority(priority),
                          itemBuilder: (_) => [
                            const PopupMenuItem<TaskPriority?>(
                              value: null,
                              child: Text('All Priorities'),
                            ),
                            ...TaskPriority.values.map(
                              (priority) => PopupMenuItem<TaskPriority?>(
                                value: priority,
                                child: Text('Priority: ${priority.label}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Filter Segmented Chips Row
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: TaskTabFilter.values.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tab = TaskTabFilter.values[index];
                        final selected = filter.tab == tab;

                        int? badgeCount;
                        if (selected && totalCount > 0) {
                          badgeCount = totalCount;
                        } else if (tab == TaskTabFilter.completed &&
                            completedCount > 0) {
                          badgeCount = completedCount;
                        }

                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(tasksFilterProvider.notifier).setTab(tab);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.surfaceMuted,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              boxShadow: selected ? AppShadows.activeChip : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tab.label,
                                  style: textTheme.labelMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                if (badgeCount != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? Colors.white.withValues(alpha: 0.22)
                                          : tab == TaskTabFilter.completed
                                              ? AppColors.successPastel
                                              : AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      '$badgeCount',
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: selected
                                            ? Colors.white
                                            : tab == TaskTabFilter.completed
                                                ? AppColors.success
                                                : AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Micro-Progress Daily Snapshot ("Today's Momentum")
                  _TodaysMomentumCard(
                    completedCount: completedCount,
                    totalCount: totalCount,
                    progressRatio: progressRatio,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Builder(
                  builder: (context) {
                    if (tasksAsync.isLoading && paginatedData == null) {
                      return const TaskListShimmer();
                    }
                    if (tasksAsync.hasError && paginatedData == null) {
                      final error = tasksAsync.error;
                      final message = error is ApiException
                          ? error.message
                          : 'Tidak dapat memuat daftar tugas.';
                      return ErrorStateCard(
                        message: message,
                        onRetry: () => ref
                            .read(tasksControllerProvider.notifier)
                            .refresh(),
                      );
                    }

                    final paginated = paginatedData!;
                    if (paginated.items.isEmpty) {
                      return AppEmptyState(
                        icon: LucideIcons.circleCheck,
                        title: filter.search.isNotEmpty
                            ? 'All caught up!'
                            : 'No tasks today 🎉',
                        subtitle: filter.search.isNotEmpty
                            ? 'No matching academic tasks found for this view.'
                            : 'Add your lecture assignments or daily targets to stay organized.',
                        actionLabel:
                            filter.search.isEmpty ? 'Add your first task' : null,
                        onAction: filter.search.isEmpty
                            ? () => _openTaskForm()
                            : null,
                      );
                    }

                    return Column(
                      children: [
                        if (paginated.isFromCache) ...[
                          const OfflineBanner(),
                          const SizedBox(height: 12),
                        ],
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => ref
                                .read(tasksControllerProvider.notifier)
                                .refresh(),
                            child: ListView.separated(
                              padding: const EdgeInsets.only(bottom: 110),
                              itemCount: paginated.items.length + 1,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index == paginated.items.length) {
                                  return const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: _ProTipBanner(),
                                  );
                                }
                                final task = paginated.items[index];
                                return TaskCard(
                                  key: ValueKey('task_${task.id}'),
                                  task: task,
                                  onToggleDone: () => _handleToggleDone(task),
                                  onTap: () => _openTaskForm(task: task),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaysMomentumCard extends StatelessWidget {
  const _TodaysMomentumCard({
    required this.completedCount,
    required this.totalCount,
    required this.progressRatio,
  });

  final int completedCount;
  final int totalCount;
  final double progressRatio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final percent = (progressRatio * 100).round();

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: progressRatio),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedValue, _) {
                        return CircularProgressIndicator(
                          value: animatedValue,
                          strokeWidth: 3.5,
                          backgroundColor: AppColors.surfaceMuted,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          strokeCap: StrokeCap.round,
                        );
                      },
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
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Momentum",
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$completedCount of $totalCount coursework items checked off',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.trendingUp,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProTipBanner extends StatelessWidget {
  const _ProTipBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardSmall),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.skyPastel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.lightbulb,
              size: 20,
              color: AppColors.sky,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip for Finals',
                  style: textTheme.labelMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tackle High priority items before 01:00 PM for peak cognitive efficiency.',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    height: 14 / 11,
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
