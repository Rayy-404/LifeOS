import 'package:flutter/material.dart';
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
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileStatisticsScreen(),
      ),
      GoRoute(
        path: AppRoutes.statistics,
        builder: (context, state) => const ProfileStatisticsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainBottomNavShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calendar,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.habits,
                builder: (context, state) => const HabitsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Bottom Navigation Bar matching Google Stitch `<nav>`:
/// `Home` · `Tasks` · `(+)` Elevated Center FAB · `Calendar` · `Habits`
class _MainBottomNavShell extends StatelessWidget {
  const _MainBottomNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  Future<void> _onQuickAdd(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.bottomNavTop),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F5B5BF6),
              blurRadius: 20,
              offset: Offset(0, -4),
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
                        onTap: () => navigationShell.goBranch(0),
                      ),
                      _NavTabItem(
                        icon: LucideIcons.squareCheckBig,
                        label: 'Tasks',
                        selected: currentIndex == 1,
                        onTap: () => navigationShell.goBranch(1),
                      ),
                      const SizedBox(width: 56),
                      _NavTabItem(
                        icon: LucideIcons.calendar,
                        label: 'Calendar',
                        selected: currentIndex == 2,
                        onTap: () => navigationShell.goBranch(2),
                      ),
                      _NavTabItem(
                        icon: LucideIcons.flame,
                        label: 'Habits',
                        selected: currentIndex == 3,
                        onTap: () => navigationShell.goBranch(3),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: -20,
                  child: Semantics(
                    label: 'Add Assignment or Habit',
                    button: true,
                    child: GestureDetector(
                      onTap: () => _onQuickAdd(context),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x595B5BF6),
                              blurRadius: 16,
                              offset: Offset(0, 6),
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
                ),
              ],
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
        width: 60,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
