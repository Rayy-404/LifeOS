import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../onboarding_seen_controller.dart';
import '../widgets/auth_logo_badge.dart';

/// S-01 Onboarding — matches Google Stitch `Onboarding` screen (`7cc2be025eb9448bac3243fbb79be32e`).
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (context.mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthLogoBadge(size: 44),
              const SizedBox(height: 24),
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Your Life,\n'),
                    TextSpan(
                      text: 'Organized\n',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(text: 'in One Place'),
                  ],
                ),
                style: textTheme.headlineMedium?.copyWith(
                  fontSize: 32,
                  height: 1.15,
                  letterSpacing: -0.64,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Track your tasks, classes, and habits — all in one calm dashboard.',
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const Expanded(
                child: Center(
                  child: _StitchHeroIllustration(),
                ),
              ),
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.hero,
                ),
                child: ElevatedButton(
                  key: const ValueKey('onboarding_get_started'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                  onPressed: () => _continue(context, ref),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(LucideIcons.arrowRight, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: GestureDetector(
                  onTap: () => _continue(context, ref),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Already have an account? ',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          TextSpan(
                            text: 'Log In',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StitchHeroIllustration extends StatelessWidget {
  const _StitchHeroIllustration();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.cardLarge),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: AppShadows.card,
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          'assets/images/onboarding_hero.png',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 280,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.cardLarge),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.laptop,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
