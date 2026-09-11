import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';
import '../invite/invite_service.dart';
import 'manage_admins_screen.dart';
import 'manage_users_screen.dart';
import 'owner_stats_screen.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final role = context.watch<RoleViewController>().activeRole;
    final theme = Theme.of(context);

    if (role != 'owner') {
      return AppScaffold(
        body: Center(
          child: Text(
            'Access denied\n(Owner only)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return const AppScaffold(
      notificationCount: 0,
      body: _OwnerDashboardBody(),
    );
  }
}

//
// ================= DASHBOARD BODY =================
//

class _OwnerDashboardBody extends StatelessWidget {
  const _OwnerDashboardBody();

  @override
  Widget build(BuildContext context) {

    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [

        _UsersTile(),
        SizedBox(height: 12),

        _AdminsTile(),
        SizedBox(height: 12),

        _InviteMuftiTile(),
        SizedBox(height: 12),

        _StatsTile(),
      ],
    );
  }
}

//
// ================= USERS TILE =================
//

class _UsersTile extends StatelessWidget {
  const _UsersTile();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return _PanelTile(
      icon: Icons.people,
      title: "Manage Users",
      subtitle: "View & manage all registered users",
      color: theme.colorScheme.primary,
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ManageUsersScreen(),
          ),
        );
      },
    );
  }
}

//
// ================= INVITE MUFTI =================
//

class _InviteMuftiTile extends StatelessWidget {
  const _InviteMuftiTile();

  void _showInviteDialog(BuildContext context) {

    final theme = Theme.of(context);

    final emailController = TextEditingController();
    final inviteService = InviteService();

    showDialog(

      context: context,

      builder: (dialogContext) => AlertDialog(

        title: Text(
          'Invite Mufti',
          style: theme.textTheme.titleMedium,
        ),

        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            hintText: 'Enter Mufti email',
          ),
        ),

        actions: [

          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          TextButton(
            onPressed: () async {

              final email = emailController.text.trim();
              if (email.isEmpty) return;

              final inviteId =
              await inviteService.createInvite(email);

              if (!dialogContext.mounted) return;

              if (inviteId == null) {

                ScaffoldMessenger.of(dialogContext)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Invite already exists',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invite created!\nID: $inviteId',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            },
            child: Text(
              'Invite',
              style: TextStyle(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return _PanelTile(
      icon: Icons.person_add,
      title: "Invite Mufti",
      subtitle: "Send invitation to join as Mufti",
      color: theme.colorScheme.secondary,
      onTap: () => _showInviteDialog(context),
    );
  }
}

//
// ================= ADMINS =================
//

class _AdminsTile extends StatelessWidget {
  const _AdminsTile();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return _PanelTile(
      icon: Icons.admin_panel_settings,
      title: "Manage Admins",
      subtitle: "Promote / Demote admins",
      color: theme.colorScheme.tertiary,
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ManageAdminsScreen(),
          ),
        );
      },
    );
  }
}

//
// ================= STATS =================
//

class _StatsTile extends StatelessWidget {
  const _StatsTile();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return _PanelTile(
      icon: Icons.analytics,
      title: "System Statistics",
      subtitle: "Users, Questions, Activity",
      color: theme.colorScheme.primary,
      onTap: () {

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const OwnerStatsScreen(),
          ),
        );
      },
    );
  }
}

//
// ================= PANEL TILE =================
//

class _PanelTile extends StatelessWidget {

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PanelTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Card(

      elevation: 1.5,

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.15),
          child: Icon(icon, color: color),
        ),

        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium,
        ),

        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: theme.colorScheme.primary,
        ),

        onTap: onTap,
      ),
    );
  }
}