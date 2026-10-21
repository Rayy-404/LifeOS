import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_logo_badge.dart';
import '../../../habits/presentation/habits_controller.dart';
import '../../../reminders/presentation/reminders_controller.dart';
import '../../../statistics/domain/statistics.dart';
import '../../../statistics/presentation/statistics_controller.dart';

/// S-10 Statistics & Profile — real data from `/statistics/overview`,
/// `/statistics/weekly`, `/habits`, and `/reminders` (`DESIGN.md` S-10).
class ProfileStatisticsScreen extends ConsumerStatefulWidget {
  const ProfileStatisticsScreen({super.key});

  @override
  ConsumerState<ProfileStatisticsScreen> createState() =>
      _ProfileStatisticsScreenState();
}

class _ProfileStatisticsScreenState
    extends ConsumerState<ProfileStatisticsScreen> {
  int _selectedTab = 0;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'Sesi, cache lokal, dan seluruh notifikasi terjadwal akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await ref
        .read(localNotificationServiceProvider)
        .requestPermissions();
    ref.invalidate(notificationPermissionProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? 'Notifikasi lokal aktif.'
              : 'Izin ditolak. Aktifkan lewat Pengaturan Android → Apps → '
                  'LifeOS → Notifications.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final statisticsAsync = ref.watch(statisticsControllerProvider);
    final statistics = statisticsAsync.value;
    final habits = ref.watch(habitsControllerProvider).value?.items ?? const [];
    final reminders = ref.watch(remindersControllerProvider).value;
    final permission = ref.watch(notificationPermissionProvider);

    final userName = user?.name ?? 'LifeOS User';
    final userEmail = user?.email ?? '';
    final userTimezone = user?.timezone ?? 'Asia/Jakarta';
    final initials = userName.trim().isNotEmpty
        ? userName.trim().substring(0, 1).toUpperCase()
        : 'L';
    final maxStreak = habits.fold<int>(
      0,
      (current, habit) => math.max(current, habit.currentStreak),
    );
    final scheduledReminderCount = reminders?.scheduledCount ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.dashboard);
                        }
                      },
                      icon: const Icon(
                        LucideIcons.chevronLeft,
                        size: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const AuthLogoBadge(size: 30, accentBottomRight: true),
                    const SizedBox(width: 8),
                    Text(
                      'Profile & Statistics',
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => showAboutDialog(
                        context: context,
                        applicationName: 'LifeOS',
                        applicationVersion: '1.0.0 MVP',
                      ),
                      tooltip: 'About LifeOS',
                      icon: const Icon(
                        LucideIcons.circleHelp,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref
                    .read(statisticsControllerProvider.notifier)
                    .refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    if (statistics?.isFromCache ?? false) const OfflineBanner(),
                    _ProfileHeader(
                      initials: initials,
                      userName: userName,
                      userEmail: userEmail,
                      tasksTotal: statistics?.currentWeek.tasks.total ?? 0,
                      habitsTotal: habits.length,
                      maxStreak: maxStreak,
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  children: [
                                    _TabPill(
                                      label: 'Overview',
                                      selected: _selectedTab == 0,
                                      onTap: () =>
                                          setState(() => _selectedTab = 0),
                                    ),
                                    _TabPill(
                                      label: 'Tasks',
                                      selected: _selectedTab == 1,
                                      onTap: () =>
                                          setState(() => _selectedTab = 1),
                                    ),
                                    _TabPill(
                                      label: 'Habits',
                                      selected: _selectedTab == 2,
                                      onTap: () =>
                                          setState(() => _selectedTab = 2),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'This Week',
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      LucideIcons.chevronDown,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (statisticsAsync.isLoading && statistics == null)
                            const TaskListShimmer(itemCount: 4)
                          else if (statisticsAsync.hasError &&
                              statistics == null)
                            ErrorStateCard(
                              message:
                                  statisticsAsync.error is ApiException
                                      ? (statisticsAsync.error as ApiException)
                                          .message
                                      : 'Gagal memuat statistik.',
                              onRetry: () => ref
                                  .read(statisticsControllerProvider.notifier)
                                  .refresh(),
                            )
                          else if (statistics != null) ...[
                            _ProductivityCard(
                              statistics: statistics,
                              selectedTab: _selectedTab,
                            ),
                            const SizedBox(height: 12),
                            _WeeklyChartCard(
                              weekly: statistics.weekly,
                              selectedTab: _selectedTab,
                            ),
                            const SizedBox(height: 12),
                            _MetricsRow(
                              statistics: statistics,
                              selectedTab: _selectedTab,
                            ),
                          ],
                          const SizedBox(height: 24),
                          Text(
                            'Preferences',
                            style: textTheme.titleMedium?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
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
                              children: [
                                _PreferenceRow(
                                  icon: LucideIcons.bellRing,
                                  iconColor: AppColors.violet,
                                  iconBg: AppColors.violetPastel,
                                  title: 'Reminders & Alerts',
                                  badgeCount: scheduledReminderCount,
                                  onTap: () =>
                                      context.push(AppRoutes.reminders),
                                ),
                                const Divider(height: 1),
                                _PreferenceRow(
                                  icon: LucideIcons.bell,
                                  iconColor: AppColors.sky,
                                  iconBg: AppColors.skyPastel,
                                  title: 'Notifications',
                                  trailingText: permission.value == false
                                      ? 'Off'
                                      : 'On',
                                  onTap: _requestNotificationPermission,
                                ),
                                const Divider(height: 1),
                                const _PreferenceRow(
                                  icon: LucideIcons.palette,
                                  iconColor: AppColors.orange,
                                  iconBg: AppColors.orangePastel,
                                  title: 'Appearance',
                                  trailingText: 'Light',
                                ),
                                const Divider(height: 1),
                                _PreferenceRow(
                                  icon: LucideIcons.clock,
                                  iconColor: AppColors.success,
                                  iconBg: AppColors.successPastel,
                                  title: 'Timezone',
                                  trailingText: userTimezone,
                                ),
                                const Divider(height: 1),
                                _PreferenceRow(
                                  icon: LucideIcons.circleHelp,
                                  iconColor: AppColors.textSecondary,
                                  iconBg: AppColors.surfaceMuted,
                                  title: 'Help & Support',
                                  onTap: () => showAboutDialog(
                                    context: context,
                                    applicationName: 'LifeOS',
                                    applicationVersion: '1.0.0 MVP',
                                    children: const [
                                      Text(
                                        'LifeOS menyatukan tugas, jadwal, '
                                        'kebiasaan, dan pengingat dalam satu '
                                        'dashboard.',
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _confirmLogout,
                              icon: const Icon(LucideIcons.logOut, size: 18),
                              label: const Text(
                                'Log Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.userName,
    required this.userEmail,
    required this.tasksTotal,
    required this.habitsTotal,
    required this.maxStreak,
  });

  final String initials;
  final String userName;
  final String userEmail;
  final int tasksTotal;
  final int habitsTotal;
  final int maxStreak;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x2E1E2140),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.settings,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            width: 68,
            height: 68,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.violet],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            userName,
            style: textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userEmail,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavyStatColumn(
                    value: '$tasksTotal',
                    label: 'Tasks',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                Expanded(
                  child: _NavyStatColumn(
                    value: '$habitsTotal',
                    label: 'Habits',
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
                Expanded(
                  child: _NavyStatColumn(
                    value: '$maxStreak Days',
                    label: 'Streak',
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

class _ProductivityCard extends StatelessWidget {
  const _ProductivityCard({
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

class _WeeklyChartCard extends StatelessWidget {
  const _WeeklyChartCard({
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
                _LegendDot(color: AppColors.primary, label: 'Completed'),
                SizedBox(width: 14),
                _LegendDot(color: AppColors.primarySoft, label: 'Scheduled'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
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
          _MetricData('Completed', '${tasks.completed}', AppColors.success),
          _MetricData('Overdue', '${tasks.overdue}', AppColors.error),
          _MetricData('Total', '${tasks.total}', AppColors.primary),
        ],
      2 => [
          _MetricData(
            'Completed',
            '${habits.totalCompletedInstances}',
            AppColors.success,
          ),
          _MetricData(
            'Scheduled',
            '${habits.totalScheduledInstances}',
            AppColors.primary,
          ),
          _MetricData(
            'Consistency',
            '${habits.consistencyRate.toStringAsFixed(1)}%',
            AppColors.violet,
          ),
        ],
      _ => [
          _MetricData('Tasks Done', '${tasks.completed}', AppColors.success),
          _MetricData('Overdue', '${tasks.overdue}', AppColors.error),
          _MetricData(
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
          Expanded(child: _MetricCard(data: items[index])),
        ],
      ],
    );
  }
}

class _MetricData {
  const _MetricData(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});

  final _MetricData data;

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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

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

class _NavyStatColumn extends StatelessWidget {
  const _NavyStatColumn({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.trailingText,
    this.badgeCount,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? trailingText;
  final int? badgeCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (badgeCount != null) ...[
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (trailingText != null) ...[
                  Text(
                    trailingText!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
