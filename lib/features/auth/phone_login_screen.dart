import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import '../../services/auth_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final AuthService _auth = AuthService();

  final TextEditingController _otpCtrl = TextEditingController();

  String _completePhone = '';
  String? _verificationId;

  bool _codeSent = false;
  bool _loading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMsg(
      String msg, {
        bool error = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: error ? Colors.red : Colors.green,
        ),
      );
  }

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> _sendOtp() async {
    if (_loading) return;

    if (_completePhone.isEmpty ||
        !_completePhone.startsWith('+')) {
      _showMsg(
        "Enter a valid phone number",
        error: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    await _auth.signInWithPhone(
      phone: _completePhone,

      // ========================================================
      // IMPORTANT
      //
      // This is NORMAL phone login.
      // We are NOT linking the phone to an existing user here.
      // AccountSetupScreen handles phone linking separately.
      // ========================================================

      linkToCurrentUser: false,

      codeSent: (id) {
        if (!mounted) return;

        setState(() {
          _verificationId = id;
          _codeSent = true;
          _loading = false;
        });

        _showMsg("OTP sent successfully");
      },

      onError: (error) {
        if (!mounted) return;

        setState(() {
          _loading = false;
        });

        _showMsg(
          error,
          error: true,
        );
      },
    );
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp() async {
    if (_loading) return;

    if (_verificationId == null) {
      _showMsg(
        "Request OTP first",
        error: true,
      );
      return;
    }

    final otp = _otpCtrl.text.trim();

    if (otp.length != 6) {
      _showMsg(
        "Enter the 6-digit OTP",
        error: true,
      );
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
    });

    final user = await _auth.verifyOtp(
      verificationId: _verificationId!,
      otp: otp,

      // ========================================================
      // IMPORTANT
      //
      // Normal phone login.
      // AccountSetupScreen handles linking separately.
      // ========================================================

      linkToCurrentUser: false,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (user == null) {
      _showMsg(
        "Invalid OTP or phone login failed",
        error: true,
      );
      return;
    }

    _showMsg("Login successful");

    // ==========================================================
    // AUTH STATE
    //
    // Firebase Auth state has changed.
    //
    // RootScreen will check:
    //
    // Complete profile
    //     -> MainScreen
    //
    // Incomplete profile
    //     -> AccountSetupScreen
    //
    // We don't manually decide the destination here.
    // ==========================================================

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/',
          (route) => false,
    );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Phone Login"),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.phone_android,
                size: 60,
              ),

              const SizedBox(height: 20),

              const Text(
                "Sign in with your phone number",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Enter your phone number and verify it "
                    "using the OTP.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // PHONE NUMBER
              // ==================================================

              IntlPhoneField(
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                initialCountryCode: 'IN',
                disableLengthCheck: false,

                // ------------------------------------------------
                // IMPORTANT:
                //
                // Agar OTP request ke baad phone number change
                // kiya jaye to purana verification session use
                // nahi hona chahiye.
                // ------------------------------------------------

                onChanged: (phone) {
                  final newPhone = phone.completeNumber;

                  if (_completePhone != newPhone && _codeSent) {
                    setState(() {
                      _completePhone = newPhone;
                      _verificationId = null;
                      _codeSent = false;
                      _otpCtrl.clear();
                    });

                    _showMsg(
                      "Phone number changed. Please request a new OTP.",
                      error: true,
                    );

                    return;
                  }

                  _completePhone = newPhone;
                },
              ),

              const SizedBox(height: 20),

              // ==================================================
              // OTP
              // ==================================================

              if (_codeSent)
                TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                    counterText: "",
                  ),
                ),

              const SizedBox(height: 20),

              // ==================================================
              // BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : (_codeSent
                      ? _verifyOtp
                      : _sendOtp),
                  child: _loading
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _codeSent
                        ? "Verify OTP"
                        : "Send OTP",
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              // ==================================================
              // RESEND
              // ==================================================

              if (_codeSent)
                TextButton(
                  onPressed: _loading ? null : _sendOtp,
                  child: const Text("Resend OTP"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}