import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../features/auth/domain/auth_state.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/habits/presentation/screens/habits_screen.dart';
import '../features/profile/presentation/screens/profile_statistics_screen.dart';
import '../features/reminders/presentation/screens/reminders_screen.dart';
import '../features/tasks/presentation/screens/tasks_screen.dart';
import '../features/tasks/presentation/widgets/task_form_sheet.dart';
import 'theme.dart';

/// Application route paths (`02-design-brief.md` Section 4 & `DESIGN.md` Section 5).
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String habits = '/habits';
  static const String profile = '/profile';
  static const String statistics = '/statistics';
  static const String reminders = '/reminders';
}

/// Lightweight GPU-friendly Fade + Subtle Slide page transition (220ms)
/// optimized for entry-level CPUs and 2GB RAM Android devices.
CustomTransitionPage<T> buildSmoothPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.025),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStatusListenable = ValueNotifier<AuthStatus>(AuthStatus.unknown);

  ref.listen<AuthState>(
    authControllerProvider,
    (previous, next) => authStatusListenable.value = next.status,
    fireImmediately: true,
  );
  ref.onDispose(authStatusListenable.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authStatusListenable,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;

      final isSplash = location == AppRoutes.splash;
      final isOnboarding = location == AppRoutes.onboarding;
      final isAuthRoute =
          location == AppRoutes.login || location == AppRoutes.register;
      final isPublicRoute = isAuthRoute || isOnboarding;

      switch (authState.status) {
        case AuthStatus.unknown:
          return isSplash ? null : AppRoutes.splash;
        case AuthStatus.unauthenticated:
          if (isPublicRoute || isSplash) return null;
          return AppRoutes.login;
        case AuthStatus.authenticated:
          if (isSplash || isPublicRoute) return AppRoutes.dashboard;
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.profile,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const ProfileStatisticsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const ProfileStatisticsScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.reminders,
        pageBuilder: (context, state) => buildSmoothPage(
          key: state.pageKey,
          child: const RemindersScreen(),
        ),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return _MainBottomNavShell(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return _AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                pageBuilder: (context, state) => buildSmoothPage(
                  key: state.pageKey,
                  child: const DashboardScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                pageBuilder: (context, state) => buildSmoothPage(
                  key: state.pageKey,
                  child: const TasksScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                pageBuilder: (context, state) => buildSmoothPage(
                  key: state.pageKey,
                  child: const CalendarScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                pageBuilder: (context, state) => buildSmoothPage(
                  key: state.pageKey,
                  child: const HabitsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Keeps all bottom-nav branch states alive via `IndexedStack` while playing a
/// smooth 180ms fade + subtle horizontal slide whenever the active tab changes.
/// Paints only 1 branch at a time for minimal GPU/RAM usage on 2GB devices.
class _AnimatedBranchContainer extends StatefulWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<_AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<_AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _configureAnimations(direction: 1);
  }

  void _configureAnimations({required int direction}) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slideAnimation = Tween<Offset>(
      begin: Offset(0.03 * direction, 0),
      end: Offset.zero,
    ).animate(curved);
  }

  @override
  void didUpdateWidget(covariant _AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      final direction = widget.currentIndex > oldWidget.currentIndex ? 1 : -1;
      _configureAnimations(direction: direction);
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: widget.currentIndex,
          children: widget.children,
        ),
      ),
    );
  }
}

/// Bottom Navigation Bar matching Google Stitch `<nav>`:
/// `Home` · `Tasks` · `(+)` Elevated Center FAB · `Calendar` · `Habits`
class _MainBottomNavShell extends StatelessWidget {
  const _MainBottomNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _onQuickAdd(BuildContext context) async {
    HapticFeedback.lightImpact();
    final created = await TaskFormSheet.show(context);
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 2),
          content: Text('Task created'),
        ),
      );
    }
  }

  void _selectBranch(int index) {
    if (navigationShell.currentIndex != index) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(
              top: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            child: SizedBox(
              height: 68,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Left Cluster: Home, Tasks
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SalomonNavTabItem(
                                key: const ValueKey('nav_home_tab'),
                                icon: LucideIcons.house,
                                label: 'Home',
                                selected: currentIndex == 0,
                                onTap: () => _selectBranch(0),
                              ),
                              _SalomonNavTabItem(
                                key: const ValueKey('nav_tasks_tab'),
                                icon: LucideIcons.squareCheckBig,
                                label: 'Tasks',
                                selected: currentIndex == 1,
                                onTap: () => _selectBranch(1),
                              ),
                            ],
                          ),
                        ),
                        // Center Gap for Floating Quick Add FAB
                        const SizedBox(width: 56),
                        // Right Cluster: Calendar, Habits
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _SalomonNavTabItem(
                                key: const ValueKey('nav_calendar_tab'),
                                icon: LucideIcons.calendar,
                                label: 'Calendar',
                                selected: currentIndex == 2,
                                onTap: () => _selectBranch(2),
                              ),
                              _SalomonNavTabItem(
                                key: const ValueKey('nav_habits_tab'),
                                icon: LucideIcons.flame,
                                label: 'Habits',
                                selected: currentIndex == 3,
                                onTap: () => _selectBranch(3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -18,
                    child: _QuickAddCenterFab(
                      onTap: () => _onQuickAdd(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAddCenterFab extends StatefulWidget {
  const _QuickAddCenterFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_QuickAddCenterFab> createState() => _QuickAddCenterFabState();
}

class _QuickAddCenterFabState extends State<_QuickAddCenterFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Add Assignment or Habit',
      button: true,
      child: GestureDetector(
        key: const ValueKey('nav_add_task_fab'),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.90 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: AppShadows.fab,
            ),
            child: const Icon(
              LucideIcons.plus,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated expanding pill bottom navigation tab item matching the Salomon /
/// Google Bottom Bar specification (`DESIGN.md` Section 5).
///
/// Smoothly expands horizontally upon selection, revealing the label alongside
/// the icon in an Anti-AI-Slop tinted pill container with flat solid colors and
/// crisp 1px borders.
class _SalomonNavTabItem extends StatefulWidget {
  const _SalomonNavTabItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SalomonNavTabItem> createState() => _SalomonNavTabItemState();
}

class _SalomonNavTabItemState extends State<_SalomonNavTabItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: widget.selected ? 1.0 : 0.0,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void didUpdateWidget(covariant _SalomonNavTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      if (widget.selected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final progress = _animation.value;
        final currentColor = Color.lerp(
          AppColors.textSecondary,
          AppColors.primary,
          progress,
        )!;
        final backgroundColor = Color.lerp(
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.12),
          progress,
        )!;
        final borderColor = Color.lerp(
          Colors.transparent,
          AppColors.border,
          progress,
        )!;

        return Semantics(
          label: widget.label,
          selected: widget.selected,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: widget.onTap,
              splashColor: AppColors.primary.withValues(alpha: 0.12),
              highlightColor: AppColors.primary.withValues(alpha: 0.06),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: 48,
                  minWidth: 44,
                ),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10 + (2 * progress),
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: borderColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          widget.icon,
                          size: 20,
                          color: currentColor,
                        ),
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Opacity(
                              opacity: progress.clamp(0.0, 1.0),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: currentColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
