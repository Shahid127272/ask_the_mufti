import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_scaffold.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() =>
      _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState
    extends State<AdminAnalyticsScreen> {
  bool _loading = true;

  int totalQuestions = 0;
  int pendingQuestions = 0;
  int publishedQuestions = 0;

  int totalUsers = 0;
  int totalMuftis = 0;

  int todayQuestions = 0;
  int todayPublished = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    final db = FirebaseFirestore.instance;

    final questionsSnap =
    await db.collection('questions').get();

    final usersSnap =
    await db.collection('users').get();

    final now = DateTime.now();

    final todayStart = DateTime(
      now.year,
      now.month,
      now.day,
    );

    int tq = 0;
    int pq = 0;
    int pubq = 0;
    int todayQ = 0;
    int todayPub = 0;

    for (final doc in questionsSnap.docs) {
      final data = doc.data();

      tq++;

      final status = data['status'];
      final Timestamp? createdAt = data['createdAt'];

      if (status == 'pending') {
        pq++;
      }

      if (status == 'published') {
        pubq++;
      }

      if (createdAt != null) {
        final date = createdAt.toDate();

        if (date.isAfter(todayStart)) {
          todayQ++;

          if (status == 'published') {
            todayPub++;
          }
        }
      }
    }

    int users = 0;
    int muftis = 0;

    for (final doc in usersSnap.docs) {
      final role = doc['role'];

      users++;

      if (role == 'mufti') {
        muftis++;
      }
    }

    if (!mounted) return;

    setState(() {
      totalQuestions = tq;
      pendingQuestions = pq;
      publishedQuestions = pubq;

      todayQuestions = todayQ;
      todayPublished = todayPub;

      totalUsers = users;
      totalMuftis = muftis;

      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            /// ================= QUESTIONS =================

            _SectionTitle(
              title: 'Questions',
            ),

            const SizedBox(height: 12),

            _StatCard(
              title: 'Total Questions',
              value: totalQuestions,
              icon: Icons.help_outline,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Pending Questions',
              value: pendingQuestions,
              icon: Icons.pending_actions,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Published Answers',
              value: publishedQuestions,
              icon: Icons.check_circle,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 24),

            /// ================= TODAY =================

            _SectionTitle(
              title: 'Today',
            ),

            const SizedBox(height: 12),

            _StatCard(
              title: 'Questions Today',
              value: todayQuestions,
              icon: Icons.today,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Published Today',
              value: todayPublished,
              icon: Icons.publish,
              color: theme.colorScheme.primary,
            ),

            const SizedBox(height: 24),

            /// ================= USERS =================

            _SectionTitle(
              title: 'Users',
            ),

            const SizedBox(height: 12),

            _StatCard(
              title: 'Total Users',
              value: totalUsers,
              icon: Icons.people,
              color: theme.colorScheme.primary,
            ),

            _StatCard(
              title: 'Muftis',
              value: totalMuftis,
              icon: Icons.gavel,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= SECTION TITLE =================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// ================= STAT CARD =================

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
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              color.withValues(alpha: 0.15),
              child: Icon(
                icon,
                color: color,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            Text(
              value.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
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