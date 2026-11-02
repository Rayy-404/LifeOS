import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/error_state_card.dart';
import '../../../../core/widgets/lifeos_top_header.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/widgets/shimmer_skeleton.dart';
import '../../domain/habit.dart';
import '../habits_controller.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form_sheet.dart';
import 'habit_detail_screen.dart';

/// S-08 Habits Screen — matches Google Stitch `Habits` (`8ff71f940cc74401ab480f974c8757a3`)
/// and connects to `habitsControllerProvider` (`02-design-brief.md` Section 6 S-08 & `DESIGN.md` S-08).
class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  Future<void> _handleToggleCheckIn(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    try {
      await ref
          .read(habitsControllerProvider.notifier)
          .toggleTodayCheckIn(habit);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update habit check-in.')),
      );
    }
  }

  void _openHabitDetail(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HabitDetailScreen(initialHabit: habit),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final habitsAsync = ref.watch(habitsControllerProvider);
    final snapshot = habitsAsync.value;
    final isFromCache = snapshot?.isFromCache ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const LifeOsTopHeader(title: 'Habits'),
            if (isFromCache) const OfflineBanner(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(habitsControllerProvider.notifier).refresh(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                  children: [
                    // Header Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DAILY CONSISTENCY',
                              style: textTheme.labelSmall?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Habits',
                              style: textTheme.headlineMedium?.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Semantics(
                          label: 'Tambah kebiasaan baru',
                          button: true,
                          child: GestureDetector(
                            onTap: () => HabitFormSheet.show(context),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x3D5B5BF6),
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                LucideIcons.plus,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stitch Hero Banner Card
                    const _HabitsHeroBanner(),
                    const SizedBox(height: 20),
                    // Habits List / States
                    if (habitsAsync.isLoading && snapshot == null)
                      const TaskListShimmer(itemCount: 3)
                    else if (habitsAsync.hasError && snapshot == null)
                      ErrorStateCard(
                        message: habitsAsync.error is ApiException
                            ? (habitsAsync.error as ApiException).message
                            : 'Could not load your habits.',
                        onRetry: () => ref
                            .read(habitsControllerProvider.notifier)
                            .refresh(),
                      )
                    else if (snapshot == null || snapshot.items.isEmpty)
                      AppEmptyState(
                        icon: LucideIcons.flame,
                        title: 'No habits yet',
                        subtitle:
                            'Start building positive daily routines and track your streak.',
                        actionLabel: 'Create First Habit',
                        onAction: () => HabitFormSheet.show(context),
                      )
                    else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Habits',
                                style: textTheme.titleMedium?.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Text(
                                  '${snapshot.items.where((h) => h.isActive).length} active',
                                  style: textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'This Week',
                            style: textTheme.labelMedium?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...snapshot.items.map(
                        (habit) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: HabitCard(
                            habit: habit,
                            onToggleCheckIn: () =>
                                _handleToggleCheckIn(context, ref, habit),
                            onTap: () => _openHabitDetail(context, habit),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _WeeklyInsightFooterCard(),
                    ],
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

class _HabitsHeroBanner extends StatelessWidget {
  const _HabitsHeroBanner();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E2140),
            Color(0xFF4338CA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2E1E2140),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.flag,
                      size: 13,
                      color: Color(0xFFD5D7FF),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'JOURNEY MODE',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD5D7FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Build Better Habits',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Small steps every day lead to big results. Keep the momentum going!',
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.trophy,
              color: AppColors.warning,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyInsightFooterCard extends StatelessWidget {
  const _WeeklyInsightFooterCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFFEBEBFC),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.sparkles,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WEEKLY INSIGHT',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Consistent check-ins build strong momentum. Keep your streak alive today!',
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
    );
  }
}
