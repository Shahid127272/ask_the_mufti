import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
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
    final role =
        context.read<RoleViewController>().activeRole;

    /// 🔐 ONLY OWNER ALLOWED
    if (role != 'owner') {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    /// 🚀 PARALLEL QUERIES
    final results = await Future.wait([
      _count(_db.collection('users')),
      _count(
        _db
            .collection('users')
            .where('role', isEqualTo: 'owner'),
      ),
      _count(
        _db
            .collection('users')
            .where('role', isEqualTo: 'admin'),
      ),
      _count(
        _db
            .collection('users')
            .where('role', isEqualTo: 'mufti'),
      ),
      _count(
        _db
            .collection('questions')
            .where('status', isEqualTo: 'pending'),
      ),
      _count(
        _db
            .collection('questions')
            .where('status', isEqualTo: 'answered'),
      ),
      _count(
        _db
            .collection('questions')
            .where('status', isEqualTo: 'published'),
      ),
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
    final role =
        context.watch<RoleViewController>().activeRole;

    final theme = Theme.of(context);

    /// 🔐 REALTIME ROLE LOCK
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

    /// ================= LOADING =================

    if (loading) {
      return const AppScaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    /// ================= ANALYTICS =================

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              "Users",
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            _StatTile(
              label: "Total Users",
              value: totalUsers,
              icon: Icons.people,
            ),

            _StatTile(
              label: "Owners",
              value: owners,
              icon: Icons.workspace_premium,
            ),

            _StatTile(
              label: "Admins",
              value: admins,
              icon: Icons.admin_panel_settings,
            ),

            _StatTile(
              label: "Muftis",
              value: muftis,
              icon: Icons.school,
            ),

            const SizedBox(height: 24),

            Text(
              "Questions",
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            _StatTile(
              label: "Pending",
              value: pending,
              icon: Icons.pending_actions,
            ),

            _StatTile(
              label: "Answered (Not Published)",
              value: answered,
              icon: Icons.edit_note,
            ),

            _StatTile(
              label: "Published",
              value: published,
              icon: Icons.public,
            ),
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

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}