import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.bottomNavTop),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0F5B5BF6),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 64,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NavTabItem(
                          icon: LucideIcons.house,
                          label: 'Home',
                          selected: currentIndex == 0,
                          onTap: () => _selectBranch(0),
                        ),
                        _NavTabItem(
                          icon: LucideIcons.squareCheckBig,
                          label: 'Tasks',
                          selected: currentIndex == 1,
                          onTap: () => _selectBranch(1),
                        ),
                        const SizedBox(width: 56),
                        _NavTabItem(
                          icon: LucideIcons.calendar,
                          label: 'Calendar',
                          selected: currentIndex == 2,
                          onTap: () => _selectBranch(2),
                        ),
                        _NavTabItem(
                          icon: LucideIcons.flame,
                          label: 'Habits',
                          selected: currentIndex == 3,
                          onTap: () => _selectBranch(3),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: -20,
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
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D5B5BF6),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
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

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
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
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: SizedBox(
        width: 64,
        height: 50,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutBack,
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 160),
              style: (Theme.of(context).textTheme.labelSmall ??
                      const TextStyle())
                  .copyWith(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: selected ? 14 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
