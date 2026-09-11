import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  void _showRoleDialog(String uid, String currentRole) {
    if (currentRole == 'owner' || uid == currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This user\'s role cannot be changed.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['user', 'mufti', 'admin']
              .map((role) => ListTile(
                    title: Text(role.toUpperCase()),
                    onTap: () {
                      _adminService.updateUserRole(uid, role);
                      Navigator.of(context).pop();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Users"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OwnerBadge(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("No users found"));
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

              return ListTile(
                leading: RoleBadge(role: role),
                title: Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("Role: $role"),
                onLongPress: () => _showRoleDialog(uid, role),
              );
            },
          );
        },
      ),
    );
  }
}
