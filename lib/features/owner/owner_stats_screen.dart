import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/role_view_controller.dart';

class OwnerStatsScreen extends StatefulWidget {
  const OwnerStatsScreen({super.key});

  @override
  State<OwnerStatsScreen> createState() => _OwnerStatsScreenState();
}

class _OwnerStatsScreenState extends State<OwnerStatsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool loading = true;

  int totalUsers = 0;
  int owners = 0;
  int admins = 0;
  int muftis = 0;

  int pending = 0;
  int answered = 0;
  int published = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<int> _count(Query query) async {
    final snap = await query.count().get();
    return snap.count ?? 0;
  }

  Future<void> _loadStats() async {
    final role = context.read<RoleViewController>().activeRole;

    /// 🔐 ONLY OWNER ALLOWED
    if (role != 'owner') {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
      return;
    }

    setState(() => loading = true);

    /// 🚀 PARALLEL QUERIES (FAST + SAFE)
    final results = await Future.wait([
      _count(_db.collection('users')),
      _count(_db.collection('users').where('role', isEqualTo: 'owner')),
      _count(_db.collection('users').where('role', isEqualTo: 'admin')),
      _count(_db.collection('users').where('role', isEqualTo: 'mufti')),
      _count(_db.collection('questions').where('status', isEqualTo: 'pending')),
      _count(_db.collection('questions').where('status', isEqualTo: 'answered')),
      _count(_db.collection('questions').where('status', isEqualTo: 'published')),
    ]);

    if (!mounted) return;

    setState(() {
      totalUsers = results[0];
      owners = results[1];
      admins = results[2];
      muftis = results[3];
      pending = results[4];
      answered = results[5];
      published = results[6];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 🔐 REALTIME ROLE LOCK
    final role = context.watch<RoleViewController>().activeRole;

    if (role != 'owner') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied\n(Owner only)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("System Analytics 📊")),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text("Users", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _StatTile("Total Users", totalUsers, Icons.people),
            _StatTile("Owners", owners, Icons.workspace_premium),
            _StatTile("Admins", admins, Icons.admin_panel_settings),
            _StatTile("Muftis", muftis, Icons.school),

            const SizedBox(height: 24),

            Text("Questions", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _StatTile("Pending", pending, Icons.pending_actions),
            _StatTile("Answered (Not Published)", answered, Icons.edit_note),
            _StatTile("Published", published, Icons.public),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatTile(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(label),
        trailing: Text(
          value.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
