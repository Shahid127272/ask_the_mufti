import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_management_service.dart';
import '../../core/app_scaffold.dart';
import '../admin/widgets/role_badge.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final UserManagementService _service = UserManagementService();

  String _getDisplayName(AppUser user) {
    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@').first;
    }

    return "User";
  }

  void _showDeleteDialog(AppUser user) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User?'),
        content: Text(
          'Are you sure you want to delete '
              '${_getDisplayName(user)}?\n\n'
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () {
              _service.deleteUser(user.uid);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: StreamBuilder<List<AppUser>>(
        stream: _service.watchAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading users'),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(
              child: Text('No users found'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isOwner = user.role == "owner";

              return ListTile(
                leading: RoleBadge(
                  role: user.role,
                ),
                title: Text(
                  _getDisplayName(user),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  user.email ?? 'No Email',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteDialog(user);
                    } else {
                      _service.updateUserRole(
                        user.uid,
                        value,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final items =
                    <PopupMenuEntry<String>>[];

                    if (!isOwner && user.role != 'admin') {
                      items.add(
                        const PopupMenuItem(
                          value: 'admin',
                          child: Text(
                            'Promote to Admin',
                          ),
                        ),
                      );
                    }

                    if (!isOwner && user.role != 'mufti') {
                      items.add(
                        const PopupMenuItem(
                          value: 'mufti',
                          child: Text(
                            'Promote to Mufti',
                          ),
                        ),
                      );
                    }

                    if (!isOwner && user.role != 'user') {
                      items.add(
                        const PopupMenuItem(
                          value: 'user',
                          child: Text(
                            'Demote to User',
                          ),
                        ),
                      );
                    }

                    if (!isOwner) {
                      items.add(
                        const PopupMenuDivider(),
                      );

                      items.add(
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete User',
                            style: TextStyle(
                              color:
                              Theme.of(context)
                                  .colorScheme
                                  .error,
                            ),
                          ),
                        ),
                      );
                    }

                    return items;
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}