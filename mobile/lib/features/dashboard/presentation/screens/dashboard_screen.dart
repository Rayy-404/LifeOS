import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/utils/local_date_time_helper.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../../core/widgets/task_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../calendar/domain/calendar_event.dart';
import '../../../calendar/presentation/widgets/event_form_sheet.dart';
import '../../../habits/domain/habit.dart';
import '../../../habits/presentation/screens/habit_detail_screen.dart';
import '../../../habits/presentation/widgets/habit_card.dart';
import '../../../habits/presentation/widgets/habit_form_sheet.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';
import '../dashboard_controller.dart';

/// S-04 Home Dashboard Screen — matches Google Stitch `Home` (`345944bf01fc4f8fafcdb2018f7c0587`)
/// and connects to `/api/v1/dashboard/today` (`02-design-brief.md` Section 6 S-04 & `DESIGN.md` S-04).
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  Future<void> _handleToggleTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    try {
      await ref.read(dashboardControllerProvider.notifier).toggleTaskDone(task);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  Future<void> _handleToggleHabit(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    try {
      await ref
          .read(dashboardControllerProvider.notifier)
          .toggleHabitCheckIn(habit);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.name ?? 'Rayhan').trim().split(' ').first;
    final dashAsync = ref.watch(dashboardControllerProvider);
    final snapshot = dashAsync.value;
    final isFromCache = snapshot?.isFromCache ?? false;

    final totalTasks = snapshot?.tasks.total ?? 0;
    final completedTasks = snapshot?.tasks.completed ?? 0;
    final pendingTasks = snapshot?.tasks.pending ?? 0;
    final overdueTasks = snapshot?.tasks.overdue ?? 0;
    final habitsScheduled = snapshot?.habits.scheduled ?? 0;
    final habitsCompleted = snapshot?.habits.completed ?? 0;
    final progressRatio = snapshot?.tasks.completionRatio ?? 0.0;
    final progressPercent = snapshot?.tasks.completionPercent ?? 0;
    final localDateLabel = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            const LifeOsTopHeader(title: 'Home'),
            if (isFromCache) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(dashboardControllerProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    // Greeting Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${LocalDateTimeHelper.greetingForNow()} · $localDateLabel',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      firstName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: textTheme.headlineMedium?.copyWith(
                                        fontSize: 22,
                                        height: 28 / 22,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    '👋',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Here's what's happening today.",
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (dashAsync.isLoading && snapshot == null)
                      const TaskListShimmer(itemCount: 4)
                    else if (dashAsync.hasError && snapshot == null)
                      ErrorStateCard(
                        message: dashAsync.error is ApiException
                            ? (dashAsync.error as ApiException).message
                            : 'Failed to load today summary.',
                        onRetry: () => ref
                            .read(dashboardControllerProvider.notifier)
                            .refresh(),
                      )
                    else ...[
                      // Daily Progress Hero Card
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => context.go(AppRoutes.tasks),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F5B5BF6),
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: CircularProgressIndicator(
                                        value: progressRatio,
                                        strokeWidth: 5.5,
                                        backgroundColor: AppColors.primarySoft,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    Text(
                                      '$progressPercent%',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontSize: 15,
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
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '$completedTasks of $totalTasks tasks done',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                textTheme.titleSmall?.copyWith(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: AppColors.success,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      habitsScheduled > 0
                                          ? 'Habits today: $habitsCompleted/$habitsScheduled completed'
                                          : "Keep going! You're doing great!",
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                LucideIcons.chevronRight,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 2x2 Summary Stat Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.48,
                        children: [
                          _StatTile(
                            icon: LucideIcons.calendar,
                            iconColor: AppColors.sky,
                            iconBg: AppColors.skyPastel,
                            value: '$totalTasks',
                            label: 'Total Tasks',
                          ),
                          _StatTile(
                            icon: LucideIcons.clock,
                            iconColor: AppColors.violet,
                            iconBg: AppColors.violetPastel,
                            value: '$pendingTasks',
                            label: 'Pending',
                          ),
                          _StatTile(
                            icon: LucideIcons.circleCheck,
                            iconColor: AppColors.success,
                            iconBg: AppColors.successPastel,
                            value: '$completedTasks',
                            label: 'Completed',
                          ),
                          _StatTile(
                            icon: LucideIcons.circleAlert,
                            iconColor: AppColors.error,
                            iconBg: AppColors.errorPastel,
                            value: '$overdueTasks',
                            label: 'Overdue',
                            highlightDanger: overdueTasks > 0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Quick Actions Row
                      Text(
                        'Quick Actions',
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _QuickActionButton(
                            icon: LucideIcons.clipboardPlus,
                            label: 'Add Task',
                            bgColor: AppColors.primarySoft,
                            iconColor: AppColors.primary,
                            onTap: () async {
                              await TaskFormSheet.show(context);
                            },
                          ),
                          _QuickActionButton(
                            icon: LucideIcons.calendarPlus,
                            label: 'Add Event',
                            bgColor: AppColors.orangePastel,
                            iconColor: AppColors.orange,
                            onTap: () async {
                              await EventFormSheet.show(context);
                            },
                          ),
                          _QuickActionButton(
                            icon: LucideIcons.flame,
                            label: 'New Habit',
                            bgColor: AppColors.successPastel,
                            iconColor: AppColors.success,
                            onTap: () async {
                              await HabitFormSheet.show(context);
                            },
                          ),
                          _QuickActionButton(
                            icon: LucideIcons.trendingUp,
                            label: 'Statistics',
                            bgColor: AppColors.pinkPastel,
                            iconColor: AppColors.pink,
                            onTap: () =>
                                context.push(AppRoutes.statistics),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Today's Agenda Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Agenda",
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.calendar),
                            child: Text(
                              'See Schedule',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (snapshot == null || snapshot.upcomingEvents.isEmpty)
                        _EmptySectionCard(
                          message: 'No scheduled events today.',
                          actionLabel: '+ Add Event',
                          onAction: () async {
                            await EventFormSheet.show(context);
                          },
                        )
                      else
                        ...snapshot.upcomingEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _DashboardAgendaCard(
                              event: event,
                              onTap: () => context.go(AppRoutes.calendar),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Today's Habits Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Habits",
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.habits),
                            child: Text(
                              'See All',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (snapshot == null || snapshot.todayHabits.isEmpty)
                        _EmptySectionCard(
                          message: 'No habits scheduled for today.',
                          actionLabel: '+ New Habit',
                          onAction: () async {
                            await HabitFormSheet.show(context);
                          },
                        )
                      else
                        ...snapshot.todayHabits.map(
                          (habit) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: HabitCard(
                              habit: habit,
                              variant: HabitCardVariant.dashboardCompact,
                              onToggleCheckIn: () =>
                                  _handleToggleHabit(context, ref, habit),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      HabitDetailScreen(initialHabit: habit),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Today's Tasks Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Tasks",
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(AppRoutes.tasks),
                            child: Text(
                              'See All',
                              style: textTheme.labelMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (snapshot == null || snapshot.todayTasks.isEmpty)
                        _EmptySectionCard(
                          message: 'No tasks for today. Tap to add one!',
                          actionLabel: '+ Add Task',
                          onAction: () async {
                            await TaskFormSheet.show(context);
                          },
                        )
                      else
                        ...snapshot.todayTasks.map(
                          (task) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: TaskCard(
                              task: task,
                              onToggleDone: () =>
                                  _handleToggleTask(context, ref, task),
                              onTap: () async {
                                await TaskFormSheet.show(
                                  context,
                                  initialTask: task,
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardAgendaCard extends StatelessWidget {
  const _DashboardAgendaCard({
    required this.event,
    required this.onTap,
  });

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
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
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.violet,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.violetPastel,
                            borderRadius: BorderRadius.circular(
                              AppRadius.pill,
                            ),
                          ),
                          child: Text(
                            event.formattedTimeRange,
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Event',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.title,
                      style: textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (event.location != null &&
                        event.location!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              event.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
    this.highlightDanger = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;
  final bool highlightDanger;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Icon(
                LucideIcons.ellipsis,
                size: 18,
                color: AppColors.textSecondary.withValues(alpha: 0.45),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: textTheme.displaySmall?.copyWith(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color:
                      highlightDanger ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
