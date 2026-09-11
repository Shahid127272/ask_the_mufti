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

  /// ROLE LISTENER
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

  /// LOAD DATA
  Future<void> _loadData(String? role) async {
    if (role != 'admin' && role != 'owner') {
      if (!mounted) return;

      setState(() => _loading = false);
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final results =
      await Future.wait<AggregateQuerySnapshot>([
        _db
            .collection('users')
            .where('role', isEqualTo: 'mufti')
            .count()
            .get(),

        _db
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .count()
            .get(),

        _db
            .collection('questions')
            .where('status', isEqualTo: 'pending')
            .count()
            .get(),

        _db
            .collection('questions')
            .where('status', isEqualTo: 'published')
            .count()
            .get(),
      ]);

      if (!mounted) return;

      setState(() {
        _muftiCount =
            results[0].count ?? 0;

        _adminCount =
            results[1].count ?? 0;

        _pendingQuestions =
            results[2].count ?? 0;

        _publishedQuestions =
            results[3].count ?? 0;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  bool get _isOwner =>
      _lastRole == 'owner';

  /// UI
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return AppScaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

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

    return AppScaffold(
      notificationCount: 0,
      body: RefreshIndicator(
        onRefresh: () =>
            _loadData(_lastRole),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // STAT CARDS
            // ==================================================

            _StatCard(
              'Total Muftis',
              _muftiCount,
              Icons.school,
              theme.colorScheme.primary,
            ),

            _StatCard(
              'Total Admins',
              _adminCount,
              Icons.admin_panel_settings,
              theme.colorScheme.secondary,
            ),

            _StatCard(
              'Pending Questions',
              _pendingQuestions,
              Icons.pending_actions,
              theme.colorScheme.tertiary,
            ),

            _StatCard(
              'Published Answers',
              _publishedQuestions,
              Icons.check_circle,
              theme.colorScheme.primary,
            ),

            const SizedBox(height: 24),

            Text(
              'Management',
              style: theme.textTheme.titleMedium,
            ),

            const SizedBox(height: 12),

            // ==================================================
            // MANAGE QUESTIONS
            // ==================================================

            ListTile(
              leading: Icon(
                Icons.question_answer,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Manage Questions',
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageQuestionsScreen(),
                ),
              ),
            ),

            Divider(
              color: theme.dividerColor,
            ),

            // ==================================================
            // MANAGE MUFTIS
            // ==================================================

            ListTile(
              leading: Icon(
                Icons.person_add,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Manage Muftis',
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageMuftiScreen(),
                ),
              ),
            ),

            Divider(
              color: theme.dividerColor,
            ),

            // ==================================================
            // MANAGE SUGGESTIONS
            // ==================================================

            ListTile(
              leading: Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Manage Suggestions',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: const Text(
                'View private user suggestions',
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const ManageSuggestionsScreen(),
                ),
              ),
            ),

            Divider(
              color: theme.dividerColor,
            ),

            // ==================================================
            // INVITE MUFTI
            // ==================================================

            ListTile(
              leading: Icon(
                Icons.mail_outline,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Invite Mufti',
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const InviteMuftiScreen(),
                ),
              ),
            ),

            Divider(
              color: theme.dividerColor,
            ),

            // ==================================================
            // ANALYTICS
            // ==================================================

            ListTile(
              leading: Icon(
                Icons.analytics,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Admin Analytics',
                style: theme.textTheme.titleMedium,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const AdminStatsScreen(),
                ),
              ),
            ),

            // ==================================================
            // OWNER CONTROLS
            // ==================================================

            if (_isOwner) ...[
              const SizedBox(height: 24),

              Text(
                'Owner Controls',
                style: theme.textTheme.titleMedium,
              ),

              const SizedBox(height: 12),

              ListTile(
                leading: Icon(
                  Icons.security,
                  color: theme.colorScheme.primary,
                ),
                title: Text(
                  'Manage Admins',
                  style: theme.textTheme.titleMedium,
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
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
/// STAT CARD
/// ============================================================

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard(
      this.title,
      this.value,
      this.icon,
      this.color,
      );

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