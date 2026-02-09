import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final auth = AuthService();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  String? verificationId;
  bool codeSent = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '+91XXXXXXXXXX',
              ),
            ),

            if (codeSent)
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'OTP',
                ),
              ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: Text(codeSent ? 'Verify OTP' : 'Send OTP'),
              onPressed: () async {
                if (!codeSent) {
                  await auth.signInWithPhone(
                    phone: phoneCtrl.text,
                    codeSent: (id) {
                      setState(() {
                        verificationId = id;
                        codeSent = true;
                      });
                    },
                    onError: (err) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(err)));
                    },
                  );
                } else {
                  final user = await auth.verifyOtp(
                    verificationId: verificationId!,
                    smsCode: otpCtrl.text,
                  );
                  if (user != null && context.mounted) {
                    Navigator.pushReplacementNamed(context, '/');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
