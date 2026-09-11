import 'package:flutter/material.dart';
import '../donation/donation_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About App")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "About Ask The Mufti",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Ask The Mufti is an Islamic question-answer platform where users can ask religious questions and receive authentic guidance from qualified scholars.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              "Our Mission",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "To provide a reliable and accessible platform for the Muslim community to seek knowledge and clarify religious matters in light of authentic Islamic teachings.",
            ),
            const SizedBox(height: 16),
            const Text(
              "Service Description",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Users can post questions across various categories such as Aqaaid, Ibaadaat, and more. Qualified Muftis review and provide detailed answers to help guide users.",
            ),
            const SizedBox(height: 24),
            const Text(
              "Support Us",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "This project is a community effort. Your support helps us maintain the platform and reach more people with authentic guidance.",
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.volunteer_activism),
                label: const Text("Support This Project"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DonationScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
