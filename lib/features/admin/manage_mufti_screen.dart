import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'widgets/role_badge.dart';

class ManageMuftiScreen extends StatelessWidget {
  const ManageMuftiScreen({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  String get _currentUid => FirebaseAuth.instance.currentUser!.uid;

  /// 🔐 Change role (OWNER ONLY)
  Future<void> _setRole({
    required BuildContext context,
    required String targetUid,
    required String newRole,
    required String currentRole,
  }) async {
    /// ❌ Owner role immutable
    if (currentRole == 'owner') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner role cannot be changed'),
        ),
      );
      return;
    }

    /// ❌ Owner cannot downgrade himself
    if (targetUid == _currentUid && newRole != 'owner') {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot change your own role'),
        ),
      );
      return;
    }

    await _db.collection('users').doc(targetUid).update({
      'role': newRole,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Role updated to $newRole'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersRef = _db.collection('users');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Muftis'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ Empty
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          final users = snapshot.data!.docs;

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

              return ListTile(
                leading: RoleBadge(role: role),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isOwner ? 'Owner (full control)' : 'UID: $uid',
                  style: const TextStyle(fontSize: 12),
                ),

                /// 🔒 OWNER LOCK
                trailing: isOwner
                    ? const Icon(Icons.lock, color: Colors.grey)
                    : PopupMenuButton<String>(
                  onSelected: (value) {
                    _setRole(
                      context: context,
                      targetUid: uid,
                      newRole: value,
                      currentRole: role,
                    );
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'user',
                      child: Text('Make User'),
                    ),
                    PopupMenuItem(
                      value: 'mufti',
                      child: Text('Make Mufti'),
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
