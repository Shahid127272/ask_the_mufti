import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../role_view_controller.dart';

class RoleSwitchBadge extends StatelessWidget {
  const RoleSwitchBadge({super.key});

  Color _roleColor(String role) {
    switch (role) {
      case 'owner':
        return const Color(0xFFFF9800);
      case 'admin':
        return const Color(0xFF7E57C2);
      case 'mufti':
        return const Color(0xFF2E7D32);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.workspace_premium;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'mufti':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {

    final controller = context.watch<RoleViewController>();

    if (!controller.canSwitch) {
      return const SizedBox();
    }

    final activeRole = controller.activeRole;
    final color = _roleColor(activeRole);

    return PopupMenuButton<String>(
      tooltip: "Switch Role",

      onSelected: (role) {
        controller.setRole(role);
      },

      itemBuilder: (_) => controller.availableRoles.map((r) {

        final isActive = r == activeRole;

        return PopupMenuItem<String>(
          value: r,
          child: Row(
            children: [

              Icon(
                _roleIcon(r),
                size: 18,
                color: isActive ? _roleColor(r) : Colors.grey,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  r.toUpperCase(),
                  style: TextStyle(
                    fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? _roleColor(r) : null,
                  ),
                ),
              ),

              if (isActive)
                Icon(
                  Icons.check,
                  size: 16,
                  color: _roleColor(r),
                ),
            ],
          ),
        );

      }).toList(),

      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(22),

          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Icon(
              _roleIcon(activeRole),
              color: Colors.white,
              size: 18,
            ),

            const SizedBox(width: 6),

            Text(
              activeRole.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}