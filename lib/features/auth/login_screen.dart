import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ask The Mufti',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            /// 🔵 GOOGLE LOGIN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                onPressed: () async {
                  final user = await auth.signInWithGoogle();
                  if (user != null && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            /// 📱 PHONE LOGIN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.phone),
                label: const Text('Continue with Phone'),
                onPressed: () {
                  Navigator.pushNamed(context, '/phone-login');
                },
              ),
            ),

            const SizedBox(height: 24),

            /// ℹ️ INFO
            const Text(
              'Login is required to ask questions and view answers',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
