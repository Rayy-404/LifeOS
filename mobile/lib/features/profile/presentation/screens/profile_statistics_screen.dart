import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_controller.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../../../../core/notifications/notification_settings_controller.dart';
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

  Future<void> _showAppearanceSheet() async {
    final currentMode = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.palette, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih Tampilan (Appearance)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AppearanceOptionTile(
                  icon: LucideIcons.smartphone,
                  title: 'System Default',
                  subtitle: 'Mengikuti tema sistem perangkat',
                  selected: currentMode == ThemeMode.system,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 10),
                _AppearanceOptionTile(
                  icon: LucideIcons.sun,
                  title: 'Light Mode',
                  subtitle: 'Tema terang kontras tinggi (Nordic Slate & Ocean Blue)',
                  selected: currentMode == ThemeMode.light,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                    Navigator.of(ctx).pop();
                  },
                ),
                const SizedBox(height: 10),
                _AppearanceOptionTile(
                  icon: LucideIcons.moon,
                  title: 'Dark Mode',
                  subtitle: 'Tema gelap kontras tinggi (Deep Navy & Midnight)',
                  selected: currentMode == ThemeMode.dark,
                  onTap: () {
                    ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showNotificationSettingsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final notifSettings = ref.watch(notificationSettingsProvider);
            final permission = ref.watch(notificationPermissionProvider);
            final isPermissionGranted = permission.value ?? false;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.bellRing, size: 20, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Pengaturan Notifikasi',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPermissionGranted
                            ? AppColors.successPastel
                            : AppColors.warningPastel,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isPermissionGranted
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.warning.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPermissionGranted
                                ? LucideIcons.circleCheck
                                : LucideIcons.triangleAlert,
                            size: 18,
                            color: isPermissionGranted
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isPermissionGranted
                                  ? 'Izin notifikasi sistem aktif'
                                  : 'Izin notifikasi sistem belum aktif',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!isPermissionGranted)
                            TextButton(
                              onPressed: () async {
                                final granted = await ref
                                    .read(localNotificationServiceProvider)
                                    .requestPermissions();
                                ref.invalidate(notificationPermissionProvider);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        granted
                                            ? 'Izin notifikasi berhasil diberikan.'
                                            : 'Izin ditolak oleh sistem.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Minta Izin'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: notifSettings.enabled,
                      title: Text(
                        'Aktifkan Notifikasi Aplikasi',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Master switch pengingat dan pemberitahuan',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setEnabled(val);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: notifSettings.reminderAlerts,
                      title: Text(
                        'Peringatan Deadline & Acara',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Alarm lokal untuk tugas dan agenda kalender',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeTrackColor: AppColors.primary,
                      onChanged: notifSettings.enabled
                          ? (val) {
                              ref
                                  .read(notificationSettingsProvider.notifier)
                                  .setReminderAlerts(val);
                            }
                          : null,
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: notifSettings.sound,
                      title: Text(
                        'Suara & Getaran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Putar nada dering dan getarkan perangkat',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      activeTrackColor: AppColors.primary,
                      onChanged: notifSettings.enabled
                          ? (val) {
                              ref
                                  .read(notificationSettingsProvider.notifier)
                                  .setSound(val);
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          await ref
                              .read(localNotificationServiceProvider)
                              .showNotification(
                                title: 'Pengingat LifeOS Berhasil! 🔔',
                                body:
                                    'Notifikasi lokal perangkat Anda berfungsi dengan normal.',
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifikasi uji coba berhasil dikirim!'),
                              ),
                            );
                          }
                        },
                        icon: const Icon(LucideIcons.bellRing, size: 18),
                        label: const Text(
                          'Kirim Notifikasi Uji Coba',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showTimezoneSheet(String currentTz) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.bottomSheetTop),
        ),
      ),
      builder: (ctx) {
        final now = DateTime.now();
        final timeStr =
            DateFormat('HH:mm:ss · d MMMM yyyy', 'id_ID').format(now);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.clock, size: 20, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Zona Waktu (Timezone)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: Icon(LucideIcons.x, size: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Zona Waktu Aktif',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentTz,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waktu lokal sekarang: $timeStr',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Zona waktu dideteksi secara otomatis dari perangkat Anda untuk '
                  'memastikan jadwal tugas, kalender, dan notifikasi pengingat akurat.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
    final notifSettings = ref.watch(notificationSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);

    final appearanceText = switch (themeMode) {
      ThemeMode.system => 'System',
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
    };

    final notifText = !notifSettings.enabled
        ? 'Off'
        : (permission.value == false ? 'Disabled' : 'On');

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
                      icon: Icon(
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
                      icon: Icon(
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
                                    Icon(
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
                              borderRadius: BorderRadius.circular(AppRadius.cardSmall),
                              border: Border.all(color: AppColors.border, width: 1),
                              boxShadow: AppShadows.card,
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
                                  key: const ValueKey('profile_notifications_row'),
                                  icon: LucideIcons.bell,
                                  iconColor: AppColors.sky,
                                  iconBg: AppColors.skyPastel,
                                  title: 'Notifications',
                                  trailingText: notifText,
                                  onTap: _showNotificationSettingsSheet,
                                ),
                                const Divider(height: 1),
                                PreferenceRow(
                                  key: const ValueKey('profile_appearance_row'),
                                  icon: LucideIcons.palette,
                                  iconColor: AppColors.orange,
                                  iconBg: AppColors.orangePastel,
                                  title: 'Appearance',
                                  trailingText: appearanceText,
                                  onTap: _showAppearanceSheet,
                                ),
                                const Divider(height: 1),
                                PreferenceRow(
                                  key: const ValueKey('profile_timezone_row'),
                                  icon: LucideIcons.clock,
                                  iconColor: AppColors.success,
                                  iconBg: AppColors.successPastel,
                                  title: 'Timezone',
                                  trailingText: userTimezone,
                                  onTap: () => _showTimezoneSheet(userTimezone),
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
                                side: BorderSide(
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

class _AppearanceOptionTile extends StatelessWidget {
  const _AppearanceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(
                LucideIcons.check,
                size: 18,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}
