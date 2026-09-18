import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class OwnerBadge extends StatelessWidget {
  final double size;

  const OwnerBadge({
    super.key,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.ownerPrimary;
    final primaryDark = AppTheme.ownerPrimaryDark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primary,
            primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: size,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            "OWNER",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: size - 2,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}