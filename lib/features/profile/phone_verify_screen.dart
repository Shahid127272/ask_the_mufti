import 'package:flutter/material.dart';

import '../../services/phone_auth_service.dart';
import '../../services/profile_service.dart';

class PhoneVerifyScreen extends StatefulWidget {

  final String phone;

  const PhoneVerifyScreen({
    super.key,
    required this.phone,
  });

  @override
  State<PhoneVerifyScreen> createState() =>
      _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState
    extends State<PhoneVerifyScreen> {

  final TextEditingController otpController =
  TextEditingController();

  final PhoneAuthService authService =
  PhoneAuthService();

  bool loading = false;

  @override
  void initState() {
    super.initState();

    /// SEND OTP
    authService.sendOTP(
      phone: widget.phone,
      codeSent: (verificationId) {
        /// verificationId automatically handled
      },
    );
  }

  /// VERIFY OTP

  Future<void> verify() async {

    final otp = otpController.text.trim();

    if (otp.length != 6) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter valid OTP"),
        ),
      );

      return;
    }

    setState(() => loading = true);

    try {

      await authService.verifyOTP(otp);

      /// update phone in firestore
      await ProfileService()
          .updatePhone(widget.phone);

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("OTP verification failed"),
        ),
      );
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Verify Phone"),
      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Text(
              "Enter OTP sent to ${widget.phone}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            TextField(

              controller: otpController,

              keyboardType: TextInputType.number,

              decoration: const InputDecoration(
                labelText: "OTP Code",
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed:
                loading ? null : verify,

                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Verify"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}