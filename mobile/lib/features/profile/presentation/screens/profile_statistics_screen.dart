import 'dart:math' as math;

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
import '../../../statistics/presentation/statistics_controller.dart';
import '../widgets/analytics_tab_pill.dart';
import '../widgets/preference_row.dart';
import '../widgets/productivity_score_card.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/statistics_metrics_row.dart';
import '../widgets/weekly_trend_chart_card.dart';

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
      backgroundColor: AppColors.background,
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
                    ProfileHeaderCard(
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
                                    AnalyticsTabPill(
                                      label: 'Overview',
                                      selected: _selectedTab == 0,
                                      onTap: () =>
                                          setState(() => _selectedTab = 0),
                                    ),
                                    AnalyticsTabPill(
                                      label: 'Tasks',
                                      selected: _selectedTab == 1,
                                      onTap: () =>
                                          setState(() => _selectedTab = 1),
                                    ),
                                    AnalyticsTabPill(
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
                            ProductivityScoreCard(
                              statistics: statistics,
                              selectedTab: _selectedTab,
                            ),
                            const SizedBox(height: 12),
                            WeeklyTrendChartCard(
                              weekly: statistics.weekly,
                              selectedTab: _selectedTab,
                            ),
                            const SizedBox(height: 12),
                            StatisticsMetricsRow(
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
                                PreferenceRow(
                                  key: const ValueKey('profile_reminders_row'),
                                  icon: LucideIcons.bellRing,
                                  iconColor: AppColors.violet,
                                  iconBg: AppColors.violetPastel,
                                  title: 'Reminders & Alerts',
                                  badgeCount: scheduledReminderCount,
                                  onTap: () =>
                                      context.push(AppRoutes.reminders),
                                ),
                                const Divider(height: 1),
                                PreferenceRow(
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
                                const PreferenceRow(
                                  icon: LucideIcons.palette,
                                  iconColor: AppColors.orange,
                                  iconBg: AppColors.orangePastel,
                                  title: 'Appearance',
                                  trailingText: 'Light',
                                ),
                                const Divider(height: 1),
                                PreferenceRow(
                                  icon: LucideIcons.clock,
                                  iconColor: AppColors.success,
                                  iconBg: AppColors.successPastel,
                                  title: 'Timezone',
                                  trailingText: userTimezone,
                                ),
                                const Divider(height: 1),
                                PreferenceRow(
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
                              key: const ValueKey('profile_logout'),
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
