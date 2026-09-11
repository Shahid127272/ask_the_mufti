import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Privacy Policy",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "User Data Collection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We collect information that you provide directly to us, such as when you create an account, ask a question, or communicate with us. This may include your name, email address, and phone number.",
            ),
            SizedBox(height: 16),
            Text(
              "Firebase Authentication",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We use Firebase Authentication to secure your account and manage sign-in processes. Your credentials are encrypted and managed by Google's secure infrastructure.",
            ),
            SizedBox(height: 16),
            Text(
              "Data Protection",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "We implement a variety of security measures to maintain the safety of your personal information. Your data is stored securely in Firebase Firestore.",
            ),
          ],
        ),
      ),
    );
  }
}
