import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/role_service.dart';
import 'admin_stats_screen.dart';
import 'manage_mufti_screen.dart';
import 'widgets/role_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _loading = true;
  bool _isAdmin = false;

  int _muftiCount = 0;
  int _pendingQuestions = 0;
  int _publishedQuestions = 0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _loading = true);

    final role = await RoleService().getCurrentUserRole();

    /// 🔐 HARD ADMIN (OWNER) LOCK
    if (role != 'admin') {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _loading = false;
      });
      return;
    }

    final muftisSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'mufti')
        .get();

    final pendingSnap = await _db
        .collection('questions')
        .where('status', isEqualTo: 'pending')
        .get();

    final publishedSnap = await _db
        .collection('questions')
        .where('status', isEqualTo: 'published')
        .get();

    if (!mounted) return;

    setState(() {
      _isAdmin = true;
      _muftiCount = muftisSnap.size;
      _pendingQuestions = pendingSnap.size;
      _publishedQuestions = publishedSnap.size;
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

    /// ❌ ACCESS DENIED (NON-ADMIN)
    if (!_isAdmin) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Access denied\n(Admin only)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: RoleBadge(role: 'admin'), // 👑 OWNER badge
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(
              title: 'Total Muftis',
              value: _muftiCount.toString(),
              icon: Icons.school,
              color: Colors.indigo,
            ),
            const SizedBox(height: 12),

            _StatCard(
              title: 'Pending Questions',
              value: _pendingQuestions.toString(),
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),

            _StatCard(
              title: 'Published Answers',
              value: _publishedQuestions.toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            /// 🔧 ADMIN ACTIONS
            Text(
              'Admin Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Manage Muftis'),
              subtitle: const Text('Add / remove Mufti role'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageMuftiScreen(),
                  ),
                );
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Admin Stats'),
              subtitle: const Text('Usage & activity overview'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminStatsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ==========================
/// 📊 SMALL STAT CARD
/// ==========================
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
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
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
