import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/widgets/auth_logo_badge.dart';

/// Shared top application header from Google Stitch (`Home`, `My Tasks`, `Calendar`, `Habits`).
/// Displays the LifeOS Academics brand badge, current section title, notifications trigger,
/// and user profile avatar.
class LifeOsTopHeader extends ConsumerWidget {
  const LifeOsTopHeader({
    super.key,
    required this.title,
    this.onNotificationsTap,
  });

  final String title;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final user = ref.watch(authControllerProvider).user;
    final initials = _extractInitials(user?.name ?? user?.email ?? 'R');

    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            const AuthLogoBadge(size: 34, accentBottomRight: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIFEOS ACADEMICS',
                    style: textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      height: 1.1,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              key: const ValueKey('header_bell'),
              onPressed: onNotificationsTap ??
                  () => context.push(AppRoutes.reminders),
              tooltip: 'Notifications',
              icon: const Icon(
                LucideIcons.bell,
                size: 21,
                color: Color(0xFF464555),
              ),
            ),
            const SizedBox(width: 2),
            GestureDetector(
              key: const ValueKey('header_avatar'),
              onTap: () => context.go(AppRoutes.profile),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navy, AppColors.primary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F5B5BF6),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _extractInitials(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}
