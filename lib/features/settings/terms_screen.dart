import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Terms of Service")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Terms of Service",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Islamic Etiquette",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "All users must maintain Islamic etiquette while using the platform. Respectful language is required at all times.",
            ),
            SizedBox(height: 16),
            Text(
              "Questions and Interactions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Please ask relevant and clear religious questions. Abuse of any kind, including harassment of scholars or other users, will result in account suspension.",
            ),
            SizedBox(height: 16),
            Text(
              "Platform Rules",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We reserve the right to moderate content and remove questions or comments that violate our community standards.",
            ),
          ],
        ),
      ),
    );
  }
}
