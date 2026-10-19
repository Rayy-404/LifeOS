import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../app/theme.dart';

/// Skeleton shimmer shaped like task cards (`DESIGN.md` Section 7 — no full-screen spinner).
class TaskListShimmer extends StatelessWidget {
  const TaskListShimmer({
    super.key,
    this.itemCount = 4,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceMuted,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.cardSmall),
          ),
        ),
      ),
    );
  }
}
