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
import 'theme.dart';

/// Application route paths (`02-design-brief.md` Section 4).
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String dashboard = '/dashboard';
  static const String tasks = '/tasks';
  static const String calendar = '/calendar';
  static const String habits = '/habits';
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
        path: AppRoutes.dashboard,
        builder: (context, state) => const _DashboardPlaceholderScreen(),
      ),
    ],
  );
});

/// Temporary dashboard placeholder (Fase 5 replaces it) with a working logout
/// action to smoke-test the full session lifecycle.
class _DashboardPlaceholderScreen extends ConsumerWidget {
  const _DashboardPlaceholderScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final userName = authState.user?.name ?? 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('LifeOS'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(LucideIcons.logOut),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.iconTile),
                    ),
                    child: const Icon(
                      LucideIcons.layoutGrid,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome, $userName',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Authentication is wired end-to-end. The full dashboard '
                    'arrives in Fase 5.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
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
