import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/role_view_controller.dart';
import 'widgets/role_badge.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({super.key});

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {

  bool _loading = true;
  String? _lastRole;

  int totalUsers = 0;
  int adminCount = 0;
  int muftiCount = 0;
  int userCount = 0;

  int pending = 0;
  int answered = 0;
  int published = 0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ROLE LISTENER
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role = context.watch<RoleViewController>().activeRole;

    if (_lastRole != role) {
      _lastRole = role;
      _loadStats(role);
    }
  }

  Future<void> _loadStats(String? role) async {

    if (role != 'admin' && role != 'owner') {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final results = await Future.wait([

      /// USERS
      _db.collection('users').count().get(),
      _db.collection('users').where('role', isEqualTo: 'admin').count().get(),
      _db.collection('users').where('role', isEqualTo: 'mufti').count().get(),
      _db.collection('users').where('role', isEqualTo: 'user').count().get(),

      /// QUESTIONS
      _db.collection('questions').where('status', isEqualTo: 'pending').count().get(),
      _db.collection('questions').where('status', isEqualTo: 'answered').count().get(),
      _db.collection('questions').where('status', isEqualTo: 'published').count().get(),
    ]);

    if (!mounted) return;

    setState(() {
      totalUsers = results[0].count ?? 0;
      adminCount = results[1].count ?? 0;
      muftiCount = results[2].count ?? 0;
      userCount = results[3].count ?? 0;

      pending = results[4].count ?? 0;
      answered = results[5].count ?? 0;
      published = results[6].count ?? 0;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_lastRole != 'admin' && _lastRole != 'owner') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied\n(Admin / Owner only)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Statistics'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: RoleBadge(role: _lastRole!),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadStats(_lastRole),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            Text('Users Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _StatTile('Total Users', totalUsers, Icons.people),
            _StatTile('Admins', adminCount, Icons.admin_panel_settings),
            _StatTile('Muftis', muftiCount, Icons.school),
            _StatTile('Normal Users', userCount, Icons.person),

            const Divider(height: 32),

            Text('Questions Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _StatTile('Pending Questions', pending, Icons.pending_actions),
            _StatTile('Answered (Not Published)', answered, Icons.edit_note),
            _StatTile('Published Answers', published, Icons.public),
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
