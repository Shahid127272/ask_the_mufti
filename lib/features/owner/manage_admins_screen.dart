import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_scaffold.dart';
import '../../services/admin_service.dart';
import 'widgets/owner_badge.dart';
import '../admin/widgets/role_badge.dart';

class ManageAdminsScreen extends StatefulWidget {
  const ManageAdminsScreen({super.key});

  @override
  State<ManageAdminsScreen> createState() => _ManageAdminsScreenState();
}

class _ManageAdminsScreenState extends State<ManageAdminsScreen> {
  final AdminService _adminService = AdminService();

  final String currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  void _showRoleDialog(
      String uid,
      String currentRole,
      ) {
    if (currentRole == 'owner' || uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This user\'s role cannot be changed.',
          ),
        ),
      );
      return;
    }

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            'user',
            'mufti',
            'admin',
          ].map((role) {
            final isCurrentRole = role == currentRole;

            return ListTile(
              leading: Icon(
                _roleIcon(role),
                color: isCurrentRole
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface
                    .withValues(alpha: 0.6),
              ),
              title: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: isCurrentRole
                      ? theme.colorScheme.primary
                      : null,
                  fontWeight: isCurrentRole
                      ? FontWeight.w700
                      : FontWeight.normal,
                ),
              ),
              trailing: isCurrentRole
                  ? Icon(
                Icons.check,
                color: theme.colorScheme.primary,
              )
                  : null,
              onTap: () {
                _adminService.updateUserRole(
                  uid,
                  role,
                );

                Navigator.of(dialogContext).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
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
    return AppScaffold(
      body: Column(
        children: [
          /// ================= OWNER BADGE =================

          const Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              4,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: OwnerBadge(),
            ),
          ),

          /// ================= USERS =================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                final users = snapshot.data!.docs;

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                  const Divider(),
                  itemBuilder: (context, index) {
                    final doc = users[index];

                    final data =
                    doc.data() as Map<String, dynamic>;

                    final uid = doc.id;

                    final email =
                        data['email'] ?? 'No email';

                    final role =
                        data['role'] ?? 'user';

                    return ListTile(
                      leading: RoleBadge(
                        role: role,
                      ),
                      title: Text(
                        email,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Role: $role',
                      ),
                      onLongPress: () {
                        _showRoleDialog(
                          uid,
                          role,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}