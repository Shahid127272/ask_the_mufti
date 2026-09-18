import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      notificationCount: 0,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Privacy Policy",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "User Data Collection",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "We collect information that you provide directly to us, such as when you create an account, ask a question, or communicate with us. This may include your name, email address, and phone number.",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Text(
              "Firebase Authentication",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "We use Firebase Authentication to secure your account and manage sign-in processes. Your credentials are encrypted and managed by Google's secure infrastructure.",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Text(
              "Data Protection",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "We implement a variety of security measures to maintain the safety of your personal information. Your data is stored securely in Firebase Firestore.",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}