import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme.dart';

/// Rounded brand tile used across Splash, Onboarding (S-01), Login (S-02),
/// and Register (S-03) screens (`DESIGN.md`).
class AuthLogoBadge extends StatelessWidget {
  const AuthLogoBadge({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.iconTile),
        boxShadow: const [
          BoxShadow(
            color: Color(0x335B5BF6),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        LucideIcons.layoutGrid,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
