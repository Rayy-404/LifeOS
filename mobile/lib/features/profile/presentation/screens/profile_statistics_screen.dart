import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../auth/presentation/widgets/auth_logo_badge.dart';
import '../../../tasks/presentation/tasks_controller.dart';

/// S-10 Profile & Statistics Screen — matches Google Stitch `Profile & Statistics` (`2aecf227a34547af8d5519735b1f874e`).
class ProfileStatisticsScreen extends ConsumerStatefulWidget {
  const ProfileStatisticsScreen({super.key});

  @override
  ConsumerState<ProfileStatisticsScreen> createState() =>
      _ProfileStatisticsScreenState();
}

class _ProfileStatisticsScreenState
    extends ConsumerState<ProfileStatisticsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final tasks = ref.watch(tasksControllerProvider).value?.items ?? const [];

    final userName = user?.name ?? 'Rayhan Pratama';
    final userEmail = user?.email ?? 'rayhan.pratama@mhs.ac.id';
    final userTimezone = user?.timezone ?? 'Asia/Jakarta';
    final initials = userName.trim().isNotEmpty
        ? userName.trim().substring(0, 1).toUpperCase()
        : 'R';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Stack Header
            SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
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
                      ],
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        LucideIcons.ellipsisVertical,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // Top Profile Header Card in Deep Navy
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
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
                        Stack(
                          children: [
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
                                    colors: [
                                      AppColors.primary,
                                      AppColors.violet,
                                    ],
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
                            Positioned(
                              right: 2,
                              bottom: 2,
                              child: Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.navy,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _NavyStatColumn(
                                  value: '${tasks.isNotEmpty ? tasks.length : 12}',
                                  label: 'Tasks',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                              const Expanded(
                                child: _NavyStatColumn(
                                  value: '5',
                                  label: 'Habits',
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 32,
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                              const Expanded(
                                child: _NavyStatColumn(
                                  value: '7 Days',
                                  label: 'Streak',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Analytics & Insights Section
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
                        // Card 1: Productivity Score Card
                        Container(
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
                                    const SizedBox(
                                      width: 68,
                                      height: 68,
                                      child: CircularProgressIndicator(
                                        value: 0.85,
                                        strokeWidth: 7,
                                        backgroundColor: AppColors.primarySoft,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                        strokeCap: StrokeCap.round,
                                      ),
                                    ),
                                    Text(
                                      '85%',
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
                                      'Productivity Score',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.successPastel,
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.pill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            LucideIcons.arrowUp,
                                            size: 12,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '12% vs last week',
                                            style:
                                                textTheme.labelSmall?.copyWith(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.success,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "You're on the right track!",
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
                        ),
                        const SizedBox(height: 12),
                        // Card 2: Task Completion Line Chart
                        Container(
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Task Completion',
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
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 110,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _StitchLineChartPainter(),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const [
                                  _DayAxisLabel('Mon'),
                                  _DayAxisLabel('Tue'),
                                  _DayAxisLabel('Wed'),
                                  _DayAxisLabel('Thu'),
                                  _DayAxisLabel('Fri', highlighted: true),
                                  _DayAxisLabel('Sat'),
                                  _DayAxisLabel('Sun'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Card 3: Category Breakdown
                        Container(
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
                              Text(
                                'Category Breakdown',
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Column(
                                children: [
                                  _CategoryLegendRow(
                                    color: AppColors.violet,
                                    label: 'Lectures',
                                    percent: '45%',
                                  ),
                                  SizedBox(height: 8),
                                  _CategoryLegendRow(
                                    color: AppColors.orange,
                                    label: 'Assignments',
                                    percent: '25%',
                                  ),
                                  SizedBox(height: 8),
                                  _CategoryLegendRow(
                                    color: AppColors.pink,
                                    label: 'Personal',
                                    percent: '15%',
                                  ),
                                  SizedBox(height: 8),
                                  _CategoryLegendRow(
                                    color: AppColors.success,
                                    label: 'Health',
                                    percent: '10%',
                                  ),
                                  SizedBox(height: 8),
                                  _CategoryLegendRow(
                                    color: AppColors.sky,
                                    label: 'Others',
                                    percent: '5%',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Preferences Menu Section
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
                              const _PreferenceRow(
                                icon: LucideIcons.bellRing,
                                iconColor: AppColors.violet,
                                iconBg: AppColors.violetPastel,
                                title: 'Reminders & Alerts',
                                badgeCount: 3,
                              ),
                              const Divider(height: 1),
                              const _PreferenceRow(
                                icon: LucideIcons.bell,
                                iconColor: AppColors.sky,
                                iconBg: AppColors.skyPastel,
                                title: 'Notifications',
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
                              const _PreferenceRow(
                                icon: LucideIcons.circleHelp,
                                iconColor: AppColors.textSecondary,
                                iconBg: AppColors.surfaceMuted,
                                title: 'Help & Support',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Log Out Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.errorPastel,
                              foregroundColor: AppColors.error,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => ref
                                .read(authControllerProvider.notifier)
                                .logout(),
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
          ],
        ),
      ),
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

class _DayAxisLabel extends StatelessWidget {
  const _DayAxisLabel(this.label, {this.highlighted = false});
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        color: highlighted ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _CategoryLegendRow extends StatelessWidget {
  const _CategoryLegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          percent,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String? trailingText;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
    );
  }
}

class _StitchLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(0, size.height * 0.76),
      Offset(size.width * 0.166, size.height * 0.56),
      Offset(size.width * 0.333, size.height * 0.42),
      Offset(size.width * 0.50, size.height * 0.61),
      Offset(size.width * 0.666, size.height * 0.25),
      Offset(size.width * 0.833, size.height * 0.33),
      Offset(size.width, size.height * 0.14),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.28),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(
        pt,
        i == 4 ? 4.5 : 3.5,
        Paint()..color = i == 4 ? AppColors.primary : Colors.white,
      );
      canvas.drawCircle(
        pt,
        i == 4 ? 4.5 : 3.5,
        Paint()
          ..color = i == 4 ? Colors.white : AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
