import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';

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

  /// ================= ROLE LISTENER =================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role =
        context.watch<RoleViewController>().activeRole;

    if (_lastRole != role) {
      _lastRole = role;
      _loadStats(role);
    }
  }

  /// ================= LOAD STATS =================

  Future<void> _loadStats(String? role) async {
    if (role != 'admin' && role != 'owner') {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
      });
    }

    try {
      final results = await Future.wait([
        /// ================= USERS =================

        _db.collection('users').count().get(),

        _db
            .collection('users')
            .where(
          'role',
          isEqualTo: 'admin',
        )
            .count()
            .get(),

        _db
            .collection('users')
            .where(
          'role',
          isEqualTo: 'mufti',
        )
            .count()
            .get(),

        _db
            .collection('users')
            .where(
          'role',
          isEqualTo: 'user',
        )
            .count()
            .get(),

        /// ================= QUESTIONS =================

        _db
            .collection('questions')
            .where(
          'status',
          isEqualTo: 'pending',
        )
            .count()
            .get(),

        _db
            .collection('questions')
            .where(
          'status',
          isEqualTo: 'answered',
        )
            .count()
            .get(),

        _db
            .collection('questions')
            .where(
          'status',
          isEqualTo: 'published',
        )
            .count()
            .get(),
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// ================= LOADING =================

    if (_loading) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    /// ================= ACCESS CONTROL =================

    if (_lastRole != 'admin' &&
        _lastRole != 'owner') {
      return AppScaffold(
        body: Center(
          child: Text(
            'Access denied\n(Admin / Owner only)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    /// ================= STATISTICS =================

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadStats(_lastRole),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// ================= USERS =================

            Text(
              'Users Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _StatTile(
              label: 'Total Users',
              value: totalUsers,
              icon: Icons.people,
            ),

            _StatTile(
              label: 'Admins',
              value: adminCount,
              icon: Icons.admin_panel_settings,
            ),

            _StatTile(
              label: 'Muftis',
              value: muftiCount,
              icon: Icons.school,
            ),

            _StatTile(
              label: 'Normal Users',
              value: userCount,
              icon: Icons.person,
            ),

            Divider(
              height: 32,
              color: theme.dividerColor,
            ),

            /// ================= QUESTIONS =================

            Text(
              'Questions Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            _StatTile(
              label: 'Pending Questions',
              value: pending,
              icon: Icons.pending_actions,
            ),

            _StatTile(
              label: 'Answered (Not Published)',
              value: answered,
              icon: Icons.edit_note,
            ),

            _StatTile(
              label: 'Published Answers',
              value: published,
              icon: Icons.public,
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// STAT TILE
/// ============================================================

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
    final primary = theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          primary.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: primary,
          ),
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: Text(
          value.toString(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
    );
  }
}