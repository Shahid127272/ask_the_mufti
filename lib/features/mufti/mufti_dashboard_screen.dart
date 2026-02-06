import 'package:flutter/material.dart';
import 'pending_questions_screen.dart';

class MuftiDashboardScreen extends StatelessWidget {
  const MuftiDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mufti Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.pending_actions, color: Colors.orange),
            title: const Text('Pending Questions'),
            subtitle: const Text('Answer new questions'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PendingQuestionsScreen(),
                ),
              );
            },
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.blue),
            title: const Text('Answered Questions'),
            subtitle: const Text('Answered but not published'),
            trailing: const Icon(Icons.lock_outline),
          ),
          const Divider(),

          ListTile(
            leading: const Icon(Icons.public, color: Colors.green),
            title: const Text('Published Questions'),
            subtitle: const Text('Live for users'),
            trailing: const Icon(Icons.visibility),
          ),
        ],
      ),
    );
  }
}
