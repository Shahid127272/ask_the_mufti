import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _loading = true;

  int totalQuestions = 0;
  int pendingQuestions = 0;
  int publishedQuestions = 0;

  int todayQuestions = 0;
  int todayPublished = 0;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _loading = true);

    final db = FirebaseFirestore.instance;
    final questionsSnap = await db.collection('questions').get();

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

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

      if (status == 'pending') pq++;
      if (status == 'published') pubq++;

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

    setState(() {
      totalQuestions = tq;
      pendingQuestions = pq;
      publishedQuestions = pubq;
      todayQuestions = todayQ;
      todayPublished = todayPub;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(
              title: 'Total Questions',
              value: totalQuestions,
              icon: Icons.help_outline,
              color: Colors.blue,
            ),
            _StatCard(
              title: 'Pending Questions',
              value: pendingQuestions,
              icon: Icons.pending_actions,
              color: Colors.orange,
            ),
            _StatCard(
              title: 'Published Answers',
              value: publishedQuestions,
              icon: Icons.check_circle,
              color: Colors.green,
            ),

            const SizedBox(height: 24),

            Text(
              'Today',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            _StatCard(
              title: 'Questions Today',
              value: todayQuestions,
              icon: Icons.today,
              color: Colors.indigo,
            ),
            _StatCard(
              title: 'Answers Published Today',
              value: todayPublished,
              icon: Icons.publish,
              color: Colors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

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
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
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
              value.toString(),
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
