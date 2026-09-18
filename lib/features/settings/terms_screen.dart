import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
              "Terms of Service",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Islamic Etiquette",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "All users must maintain Islamic etiquette while using the platform. Respectful language is required at all times.",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Text(
              "Questions and Interactions",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "Please ask relevant and clear religious questions. Abuse of any kind, including harassment of scholars or other users, will result in account suspension.",
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            Text(
              "Platform Rules",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "We reserve the right to moderate content and remove questions or comments that violate our community standards.",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}