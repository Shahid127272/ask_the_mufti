import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';

import 'admin_stats_screen.dart';
import 'manage_mufti_screen.dart';
import 'manage_questions_screen.dart';
import 'manage_suggestions_screen.dart';

import '../owner/manage_admins_screen.dart';
import '../invite/invite_mufti_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  bool _loading = true;
  String? _lastRole;

  int _muftiCount = 0;
  int _adminCount = 0;
  int _pendingQuestions = 0;
  int _publishedQuestions = 0;

  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  /// ================= ROLE LISTENER =================

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final role =
        context.watch<RoleViewController>().activeRole;

    if (_lastRole != role) {
      _lastRole = role;
      _loadData(role);
    }
  }

  /// ================= LOAD DATA =================

  Future<void> _loadData(String? role) async {
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
      final results =
      await Future.wait<AggregateQuerySnapshot>([
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
          isEqualTo: 'admin',
        )
            .count()
            .get(),

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
          isEqualTo: 'published',
        )
            .count()
            .get(),
      ]);

      if (!mounted) return;

      setState(() {
        _muftiCount = results[0].count ?? 0;
        _adminCount = results[1].count ?? 0;
        _pendingQuestions = results[2].count ?? 0;
        _publishedQuestions = results[3].count ?? 0;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  bool get _isOwner => _lastRole == 'owner';

  /// ================= UI =================

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

    /// ================= DASHBOARD =================

    return AppScaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadData(_lastRole),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// ================= STAT CARDS =================

            _StatCard(
              title: 'Total Muftis',
              value: _muftiCount,
              icon: Icons.school,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Total Admins',
              value: _adminCount,
              icon: Icons.admin_panel_settings,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Pending Questions',
              value: _pendingQuestions,
              icon: Icons.pending_actions,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Published Answers',
              value: _publishedQuestions,
              icon: Icons.check_circle,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 24),

            Text(
              'Management',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 12),

            /// ================= MANAGE QUESTIONS =================

            _ManagementTile(
              icon: Icons.question_answer,
              title: 'Manage Questions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageQuestionsScreen(),
                ),
              ),
            ),

            /// ================= MANAGE MUFTIS =================

            _ManagementTile(
              icon: Icons.person_add,
              title: 'Manage Muftis',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageMuftiScreen(),
                ),
              ),
            ),

            /// ================= MANAGE SUGGESTIONS =================

            _ManagementTile(
              icon: Icons.lightbulb_outline,
              title: 'Manage Suggestions',
              subtitle: 'View private user suggestions',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageSuggestionsScreen(),
                ),
              ),
            ),

            /// ================= INVITE MUFTI =================

            _ManagementTile(
              icon: Icons.mail_outline,
              title: 'Invite Mufti',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const InviteMuftiScreen(),
                ),
              ),
            ),

            /// ================= ANALYTICS =================

            _ManagementTile(
              icon: Icons.analytics,
              title: 'Admin Analytics',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AdminStatsScreen(),
                ),
              ),
            ),

            /// ================= OWNER CONTROLS =================

            if (_isOwner) ...[
              const SizedBox(height: 24),

              Text(
                'Owner Controls',
                style:
                theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              _ManagementTile(
                icon: Icons.security,
                title: 'Manage Admins',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const ManageAdminsScreen(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// ============================================================
/// MANAGEMENT TILE
/// ============================================================

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _ManagementTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        ListTile(
          leading: Icon(
            icon,
            color: primary,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          subtitle: subtitle != null
              ? Text(
            subtitle!,
            style: theme.textTheme.bodyMedium,
          )
              : null,
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: primary,
          ),
          onTap: onTap,
        ),
        Divider(
          color: theme.dividerColor,
        ),
      ],
    );
  }
}

/// ============================================================
/// STAT CARD
/// ============================================================

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
          color.withValues(alpha: 0.12),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style:
          theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Text(
          value.toString(),
          style:
          theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}