import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../../core/widgets/task_card.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/tasks_controller.dart';
import '../../../tasks/presentation/widgets/task_form_sheet.dart';

/// S-04 Home Dashboard Screen — matches Google Stitch `Home` (`345944bf01fc4f8fafcdb2018f7c0587`).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final Map<int, bool> _habitCompleted = {0: true, 1: false};

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final firstName = (user?.name ?? 'Rayhan').trim().split(' ').first;
    final tasksAsync = ref.watch(tasksControllerProvider);
    final tasks = tasksAsync.value?.items ?? const <Task>[];

    final totalTasks = tasks.length;
    final completedTasks = tasks.where((t) => t.isDone).length;
    final inProgressTasks =
        tasks.where((t) => t.status == TaskStatus.inProgress).length;
    final overdueTasks = tasks.where((t) => t.isOverdue()).length;
    final progressRatio =
        totalTasks > 0 ? completedTasks / totalTasks : 0.72;
    final progressPercent = (progressRatio * 100).round();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            const LifeOsTopHeader(title: 'Home'),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(tasksControllerProvider.notifier).refresh(),
                child: ListView(
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
                                _greeting(),
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
                                      Text(
                                        totalTasks > 0
                                            ? '$completedTasks of $totalTasks tasks done'
                                            : '4 of 6 tasks done',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
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
                                    "Keep going! You're doing great!",
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
                          value: '$inProgressTasks',
                          label: 'In Progress',
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
                          onTap: () => TaskFormSheet.show(context),
                        ),
                        _QuickActionButton(
                          icon: LucideIcons.calendarPlus,
                          label: 'Add Event',
                          bgColor: AppColors.orangePastel,
                          iconColor: AppColors.orange,
                          onTap: () => context.go(AppRoutes.calendar),
                        ),
                        _QuickActionButton(
                          icon: LucideIcons.flame,
                          label: 'New Habit',
                          bgColor: AppColors.successPastel,
                          iconColor: AppColors.success,
                          onTap: () => context.go(AppRoutes.habits),
                        ),
                        _QuickActionButton(
                          icon: LucideIcons.trendingUp,
                          label: 'Statistics',
                          bgColor: AppColors.pinkPastel,
                          iconColor: AppColors.pink,
                          onTap: () => context.go(AppRoutes.profile),
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
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => context.go(AppRoutes.calendar),
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
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
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
                                            '08:00 – 10:00',
                                            style: textTheme.labelSmall
                                                ?.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.primary,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Class',
                                          style: textTheme.labelSmall?.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kuliah Sistem Operasi',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
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
                                            'Gedung B R.204 · Prof. Bambang',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                textTheme.bodyMedium?.copyWith(
                                                  fontSize: 12,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                          ),
                                        ),
                                      ],
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
                    ),
                    const SizedBox(height: 24),
                    // Today's Habits Section
                    Text(
                      "Today's Habits",
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _HomeHabitCard(
                      title: 'Minum 2L Air',
                      streakLabel: '5 days streak',
                      icon: LucideIcons.droplet,
                      iconColor: AppColors.success,
                      iconBg: AppColors.successPastel,
                      completed: _habitCompleted[0] ?? true,
                      onToggle: () => setState(() {
                        _habitCompleted[0] = !(_habitCompleted[0] ?? true);
                      }),
                    ),
                    const SizedBox(height: 8),
                    _HomeHabitCard(
                      title: 'Review Jurnal AI',
                      streakLabel: '3 days streak',
                      icon: LucideIcons.bookOpen,
                      iconColor: AppColors.violet,
                      iconBg: AppColors.violetPastel,
                      completed: _habitCompleted[1] ?? false,
                      onToggle: () => setState(() {
                        _habitCompleted[1] = !(_habitCompleted[1] ?? false);
                      }),
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
                    if (tasks.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No tasks yet. Tap (+) to add one!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => TaskFormSheet.show(context),
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      )
                    else
                      ...tasks.take(3).map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: TaskCard(
                                task: task,
                                onToggleDone: () => ref
                                    .read(tasksControllerProvider.notifier)
                                    .toggleTaskDone(task),
                                onTap: () => TaskFormSheet.show(
                                  context,
                                  initialTask: task,
                                ),
                              ),
                            ),
                          ),
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

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String value;
  final String label;

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
                  color: AppColors.textPrimary,
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

class _HomeHabitCard extends StatelessWidget {
  const _HomeHabitCard({
    required this.title,
    required this.streakLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.completed,
    required this.onToggle,
  });

  final String title;
  final String streakLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool completed;
  final VoidCallback onToggle;

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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
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
                  const SizedBox(height: 2),
                  Text(
                    '🔥 $streakLabel',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: completed ? AppColors.success : AppColors.surfaceMuted,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.check,
                size: 18,
                color: completed ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
