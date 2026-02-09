import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  Future<Map<String, int>> _loadStats() async {
    final db = FirebaseFirestore.instance;

    /// USERS
    final usersSnap = await db.collection('users').get();

    final totalUsers = usersSnap.size;
    final owners =
        usersSnap.docs.where((d) => d['role'] == 'owner').length;
    final muftis =
        usersSnap.docs.where((d) => d['role'] == 'mufti').length;

    /// QUESTIONS
    final questionsSnap = await db.collection('questions').get();

    final pending = questionsSnap.docs
        .where((d) => d['status'] == 'pending')
        .length;

    final answered = questionsSnap.docs
        .where((d) => d['status'] == 'answered')
        .length;

    final published = questionsSnap.docs
        .where((d) => d['status'] == 'published')
        .length;

    return {
      'users': totalUsers,
      'owners': owners,
      'muftis': muftis,
      'pending': pending,
      'answered': answered,
      'published': published,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Statistics'),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _loadStats(),
        builder: (context, snapshot) {
          /// ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ Error
          if (!snapshot.hasData) {
            return const Center(
              child: Text('Unable to load statistics'),
            );
          }

          final stats = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StatTile(
                label: 'Total Users',
                value: stats['users']!,
                icon: Icons.people,
              ),
              _StatTile(
                label: 'Owners',
                value: stats['owners']!,
                icon: Icons.verified,
              ),
              _StatTile(
                label: 'Muftis',
                value: stats['muftis']!,
                icon: Icons.school,
              ),
              const Divider(height: 32),
              _StatTile(
                label: 'Pending Questions',
                value: stats['pending']!,
                icon: Icons.pending_actions,
              ),
              _StatTile(
                label: 'Answered (Not Published)',
                value: stats['answered']!,
                icon: Icons.edit_note,
              ),
              _StatTile(
                label: 'Published Answers',
                value: stats['published']!,
                icon: Icons.public,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ==========================
/// 📊 STAT TILE WIDGET
/// ==========================
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
