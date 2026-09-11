import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/role_badge.dart';

class ManageMuftiScreen extends StatefulWidget {
  const ManageMuftiScreen({super.key});

  @override
  State<ManageMuftiScreen> createState() => _ManageMuftiScreenState();
}

class _ManageMuftiScreenState extends State<ManageMuftiScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  String? _currentUserRole;
  bool _loadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
  }

  Future<void> _loadCurrentUserRole() async {
    final doc = await _db.collection('users').doc(_currentUid).get();

    if (!mounted) return;

    setState(() {
      _currentUserRole = doc.data()?['role'] ?? 'user';
      _loadingRole = false;
    });
  }

  bool get _isOwner => _currentUserRole == 'owner';
  bool get _isAdmin => _currentUserRole == 'admin';
  bool get _canManageRoles => _isOwner || _isAdmin;

  // ================= ROLE CHANGE (SAFE) =================

  Future<void> _setRole({
    required BuildContext context,
    required String targetUid,
    required String newRole,
    required String targetCurrentRole,
  }) async {

    /// ❌ Only owner/admin allowed
    if (!_canManageRoles) {
      _showMessage(context, 'You are not allowed to change roles');
      return;
    }

    /// ❌ Owner role cannot be modified
    if (targetCurrentRole == 'owner') {
      _showMessage(context, 'Owner role cannot be changed');
      return;
    }

    /// ❌ Cannot change your own role
    if (targetUid == _currentUid) {
      _showMessage(context, 'You cannot change your own role');
      return;
    }

    /// ❌ Admin limitations
    if (_isAdmin) {
      if (targetCurrentRole == 'admin') {
        _showMessage(context, 'Admin cannot modify another admin');
        return;
      }

      if (newRole == 'admin' || newRole == 'owner') {
        _showMessage(context, 'Admin cannot assign this role');
        return;
      }
    }

    // ⭐ capture messenger BEFORE await
    final messenger = ScaffoldMessenger.of(context);

    await _db.collection('users').doc(targetUid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;

    messenger.showSnackBar(
      SnackBar(content: Text('Role updated to $newRole')),
    );
  }

  // ================= MESSAGE =================

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    if (_loadingRole) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// 🔐 Hard Access Gate
    if (!_canManageRoles) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access Denied\n(Owner / Admin only)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RoleBadge(role: _currentUserRole!),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('users').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const Divider(),

            itemBuilder: (context, index) {
              final doc = users[index];
              final data = doc.data() as Map<String, dynamic>;

              final uid = doc.id;
              final email = data['email'] ?? 'No email';
              final role = data['role'] ?? 'user';

              final isOwner = role == 'owner';
              final isSelf = uid == _currentUid;

              return ListTile(
                leading: RoleBadge(role: role),

                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                subtitle: Text(
                  isOwner ? 'Owner (Full Authority)' : 'UID: $uid',
                  style: const TextStyle(fontSize: 12),
                ),

                trailing: (isOwner || isSelf)
                    ? const Icon(Icons.lock, color: Colors.grey)
                    : PopupMenuButton<String>(
                  onSelected: (value) {
                    _setRole(
                      context: context,
                      targetUid: uid,
                      newRole: value,
                      targetCurrentRole: role,
                    );
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'user',
                      child: Text('Make User'),
                    ),
                    const PopupMenuItem(
                      value: 'mufti',
                      child: Text('Make Mufti'),
                    ),
                    if (_isOwner)
                      const PopupMenuItem(
                        value: 'admin',
                        child: Text('Make Admin'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
