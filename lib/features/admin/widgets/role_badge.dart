import 'package:flutter/material.dart';

import '../../../core/theme.dart';

class RoleBadge extends StatelessWidget {
  final String role;
  final double size;

  const RoleBadge({
    super.key,
    required this.role,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedRole = role.trim().toLowerCase();

    late final Color color;
    late final IconData icon;
    late final String label;

    switch (normalizedRole) {
      case 'owner':
        color = AppTheme.primaryForRole('owner');
        icon = Icons.workspace_premium;
        label = 'Owner';
        break;

      case 'admin':
        color = AppTheme.primaryForRole('admin');
        icon = Icons.admin_panel_settings;
        label = 'Admin';
        break;

      case 'mufti':
        color = AppTheme.primaryForRole('mufti');
        icon = Icons.school;
        label = 'Mufti';
        break;

      default:
        color = AppTheme.primaryForRole('user');
        icon = Icons.person;
        label = 'User';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: size - 2,
            ),
          ),
        ],
      ),
    );
  }
}