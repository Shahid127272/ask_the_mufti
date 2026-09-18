import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_scaffold.dart';
import 'widgets/role_badge.dart';

class ManageMuftiScreen extends StatefulWidget {
  const ManageMuftiScreen({super.key});

  @override
  State<ManageMuftiScreen> createState() => _ManageMuftiScreenState();
}

class _ManageMuftiScreenState extends State<ManageMuftiScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  String? _currentUserRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final doc =
    await _db.collection('users').doc(_currentUid).get();

    if (!mounted) return;

    setState(() {
      _currentUserRole =
          doc.data()?['role'] ?? 'user';

      _loadingRole = false;
    });
  }

  bool get _isOwner =>
      _currentUserRole == 'owner';

  bool get _isAdmin =>
      _currentUserRole == 'admin';

  bool get _canManageRoles =>
      _isOwner || _isAdmin;

  // ================= ROLE CHANGE =================

  Future<void> _setRole({
    required BuildContext context,
    required String targetUid,
    required String newRole,
    required String targetCurrentRole,
  }) async {
    /// ❌ Only owner/admin allowed
    if (!_canManageRoles) {
      _showMessage(
        context,
        'You are not allowed to change roles',
      );
      return;
    }

    /// ❌ Owner cannot be modified
    if (targetCurrentRole == 'owner') {
      _showMessage(
        context,
        'Owner role cannot be changed',
      );
      return;
    }

    /// ❌ Cannot change own role
    if (targetUid == _currentUid) {
      _showMessage(
        context,
        'You cannot change your own role',
      );
      return;
    }

    /// ❌ Admin limitations
    if (_isAdmin) {
      if (targetCurrentRole == 'admin') {
        _showMessage(
          context,
          'Admin cannot modify another admin',
        );
        return;
      }

      if (newRole == 'admin' ||
          newRole == 'owner') {
        _showMessage(
          context,
          'Admin cannot assign this role',
        );
        return;
      }
    }

    final messenger =
    ScaffoldMessenger.of(context);

    try {
      await _db
          .collection('users')
          .doc(targetUid)
          .update({
        'role': newRole,
        'updatedAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Role updated to $newRole',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update role',
          ),
        ),
      );
    }
  }

  // ================= MESSAGE =================

  void _showMessage(
      BuildContext context,
      String message,
      ) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingRole) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    /// 🔐 HARD ACCESS GATE
    if (!_canManageRoles) {
      return AppScaffold(
        body: Center(
          child: Text(
            'Access Denied\n(Owner / Admin only)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return AppScaffold(
      body: Column(
        children: [
          /// ================= CURRENT ROLE =================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              4,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: RoleBadge(
                role: _currentUserRole!,
              ),
            ),
          ),

          /// ================= USERS =================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color:
                      theme.colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style:
                      theme.textTheme.bodyMedium,
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(
                    child: Text(
                      'No users found',
                    ),
                  );
                }

                final users =
                    snapshot.data!.docs;

                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found',
                    ),
                  );
                }

                return ListView.separated(
                  padding:
                  const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, __) =>
                      Divider(
                        color: theme.dividerColor,
                      ),
                  itemBuilder:
                      (context, index) {
                    final doc = users[index];

                    final data = doc.data()
                    as Map<String, dynamic>;

                    final uid = doc.id;

                    final email =
                        data['email'] ??
                            'No email';

                    final role =
                        data['role'] ??
                            'user';

                    final isOwner =
                        role == 'owner';

                    final isSelf =
                        uid == _currentUid;

                    return ListTile(
                      leading: RoleBadge(
                        role: role,
                      ),

                      title: Text(
                        email,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      subtitle: Text(
                        isOwner
                            ? 'Owner (Full Authority)'
                            : 'UID: $uid',
                        style: theme
                            .textTheme
                            .bodySmall,
                      ),

                      trailing:
                      (isOwner || isSelf)
                          ? Icon(
                        Icons.lock,
                        color: theme
                            .colorScheme
                            .onSurface
                            .withValues(
                          alpha: 0.45,
                        ),
                      )
                          : PopupMenuButton<
                          String>(
                        onSelected:
                            (value) {
                          _setRole(
                            context:
                            context,
                            targetUid:
                            uid,
                            newRole:
                            value,
                            targetCurrentRole:
                            role,
                          );
                        },
                        itemBuilder:
                            (_) => [
                          const PopupMenuItem(
                            value:
                            'user',
                            child:
                            Text(
                              'Make User',
                            ),
                          ),

                          const PopupMenuItem(
                            value:
                            'mufti',
                            child:
                            Text(
                              'Make Mufti',
                            ),
                          ),

                          if (_isOwner)
                            const PopupMenuItem(
                              value:
                              'admin',
                              child:
                              Text(
                                'Make Admin',
                              ),
                            ),
                        ],
                      ),
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