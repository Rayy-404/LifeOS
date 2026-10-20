import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

/// Rounded brand tile matching Google Stitch `Onboarding` & header logo (`#EBEBFC` with 2x2 grid).
class AuthLogoBadge extends StatelessWidget {
  const AuthLogoBadge({
    super.key,
    this.size = 44,
    this.accentBottomRight = false,
  });

  final double size;
  final bool accentBottomRight;

  @override
  Widget build(BuildContext context) {
    final padding = size * 0.227;
    final gap = size * 0.12;
    final dotRadius = size * 0.09;

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEBFC),
        borderRadius: BorderRadius.circular(size * 0.36),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F5B5BF6),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(dotRadius),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentBottomRight
                          ? AppColors.violet
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(dotRadius),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(dotRadius),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                SizedBox(width: gap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accentBottomRight
                          ? AppColors.success
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(dotRadius),
                    ),
                    child: const SizedBox.expand(),
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
