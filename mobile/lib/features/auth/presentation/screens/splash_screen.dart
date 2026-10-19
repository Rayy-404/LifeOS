import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../domain/auth_state.dart';
import '../auth_controller.dart';
import '../onboarding_seen_controller.dart';
import '../widgets/auth_logo_badge.dart';

/// Auth gate: restores the stored session (or discards it) before routing.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(authControllerProvider.notifier).loadSession();
    if (!mounted) return;

    final status = ref.read(authControllerProvider).status;
    final onboardingSeen = ref.read(onboardingSeenProvider);

    if (status == AuthStatus.authenticated) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(onboardingSeen ? AppRoutes.login : AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthLogoBadge(size: 56),
            const SizedBox(height: 20),
            Text(
              'LifeOS',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ],
        ),
      ),
    );
  }
}
