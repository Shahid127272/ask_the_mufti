import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(user?.uid ?? 'Guest'),
            const SizedBox(height: 20),
            const Text('Your activity will appear here'),
          ],
        ),
      ),
    );
  }
}
