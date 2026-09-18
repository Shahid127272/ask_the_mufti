import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_scaffold.dart';
import '../../services/profile_service.dart';
import '../../services/auth_service.dart';
import 'phone_verify_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() =>
      _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _loading = false;
  bool _initialized = false;

  bool _emailVerified = false;
  bool _phoneVerified = false;

  /// ================= SAVE PROFILE =================

  Future<void> _save() async {
    if (!_emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify email first"),
        ),
      );
      return;
    }

    if (!_phoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please verify phone number"),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    await ProfileService().updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (!mounted) return;

    setState(() => _loading = false);

    Navigator.pop(context);
  }

  /// ================= PHONE VERIFY =================

  void _verifyPhone() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhoneVerifyScreen(phone: phone),
      ),
    );

    if (result == true) {
      setState(() {
        _phoneVerified = true;
      });
    }
  }

  /// ================= EMAIL VERIFY =================

  Future<void> _verifyEmail() async {
    await AuthService().sendEmailVerification();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Verification email sent. Please verify and return to the app.",
        ),
      ),
    );

    /// Start checking verification automatically
    _startEmailVerificationCheck();
  }

  /// ================= AUTO EMAIL VERIFICATION CHECK =================

  void _startEmailVerificationCheck() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    while (mounted && !_emailVerified) {
      await Future.delayed(const Duration(seconds: 3));

      await user.reload();

      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null &&
          refreshedUser.emailVerified) {
        setState(() {
          _emailVerified = true;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verified successfully"),
          ),
        );

        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      notificationCount: 0,
      body: StreamBuilder<DocumentSnapshot>(
        stream: ProfileService().profileStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          /// Firebase se email verification detect
          _emailVerified =
              AuthService().currentUser?.emailVerified ?? false;

          /// initialize only once
          if (!_initialized) {
            _nameController.text = data["name"] ?? "";
            _emailController.text = data["email"] ?? "";
            _phoneController.text = data["phone"] ?? "";

            _initialized = true;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "Edit Profile",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              /// ================= NAME =================

              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              /// ================= EMAIL =================

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _emailVerified
                          ? Icons.verified
                          : Icons.verified_outlined,
                      color: _emailVerified
                          ? colorScheme.primary
                          : null,
                    ),
                    tooltip: "Verify Email",
                    onPressed: _verifyEmail,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ================= PHONE =================

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone",
                  prefixIcon: const Icon(Icons.phone),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _phoneVerified
                          ? Icons.verified
                          : Icons.verified_outlined,
                      color: _phoneVerified
                          ? colorScheme.primary
                          : null,
                    ),
                    tooltip: "Verify Phone",
                    onPressed: _verifyPhone,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// ================= SAVE BUTTON =================

              SizedBox(
                height: 45,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? CircularProgressIndicator(
                    color: colorScheme.onPrimary,
                  )
                      : const Text("Save Changes"),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}