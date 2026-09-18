import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/invite_service.dart';

class SignupScreen extends StatefulWidget {
  final String? inviteId;

  const SignupScreen({
    super.key,
    this.inviteId,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  final AuthService _auth = AuthService();
  final InviteService _inviteService = InviteService();

  bool loading = false;
  bool hidePass = true;
  bool hideConfirm = true;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    confirm.dispose();
    super.dispose();
  }

  // ============================================================
  // SIGNUP
  // ============================================================

  Future<void> signup() async {
    if (!_formKey.currentState!.validate()) return;

    if (loading) return;

    setState(() {
      loading = true;
    });

    final enteredEmail = email.text.trim().toLowerCase();

    try {
      // ========================================================
      // CREATE ACCOUNT
      // ========================================================

      final error = await _auth.signUp(
        email: enteredEmail,
        password: pass.text,
        // Screen Name abhi nahi lenge.
        displayName: '',
      );

      if (!mounted) return;

      if (error != null) {
        setState(() {
          loading = false;
        });

        _show(error, error: true);
        return;
      }

      // ========================================================
      // INVITED MUFTI
      // ========================================================

      if (widget.inviteId != null &&
          widget.inviteId!.trim().isNotEmpty) {
        final user =
            FirebaseAuth.instance.currentUser;

        if (user == null) {
          setState(() {
            loading = false;
          });

          _show(
            'Account created, but invitation could not be accepted.',
            error: true,
          );
          return;
        }

        try {
          await _inviteService.acceptInvite(
            inviteId: widget.inviteId!.trim(),
            uid: user.uid,
            email: enteredEmail,
          );

          if (!mounted) return;

          setState(() {
            loading = false;
          });

          _show(
            'Account created successfully. You have joined as Mufti.',
          );

          Navigator.of(context).pop();
          return;
        } catch (e) {
          if (!mounted) return;

          setState(() {
            loading = false;
          });

          _show(
            'Account created, but Mufti invitation could not be accepted.\n$e',
            error: true,
          );

          return;
        }
      }

      // ========================================================
      // NORMAL USER SIGNUP
      // ========================================================

      setState(() {
        loading = false;
      });

      _show(
        'Account created. Please verify your email.',
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _show(
        'Could not create account.\n$e',
        error: true,
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _show(
      String message, {
        bool error = false,
      }) {
    if (!mounted) return;

    final colorScheme =
        Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error
              ? colorScheme.error
              : colorScheme.primary,
        ),
      );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isMuftiInvite =
        widget.inviteId != null &&
            widget.inviteId!.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isMuftiInvite
              ? "Mufti Registration"
              : "Create Account",
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                Icon(
                  isMuftiInvite
                      ? Icons.school_outlined
                      : Icons.person_add_alt_1,
                  size: 65,
                  color: colorScheme.primary,
                ),

                const SizedBox(height: 20),

                Text(
                  isMuftiInvite
                      ? "Join Ask The Mufti as a Mufti"
                      : "Create your Ask The Mufti account",
                  textAlign: TextAlign.center,
                  style:
                  textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  isMuftiInvite
                      ? "Complete your registration using the invitation."
                      : "Create your account, complete verification, "
                      "then choose your Screen Name.",
                  textAlign: TextAlign.center,
                  style:
                  textTheme.bodyMedium?.copyWith(
                    color:
                    colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 30),

                // =================================================
                // EMAIL
                // =================================================

                TextFormField(
                  controller: email,
                  keyboardType:
                  TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.email,
                  ],
                  decoration:
                  const InputDecoration(
                    labelText: "Email",
                    border:
                    OutlineInputBorder(),
                    prefixIcon:
                    Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final v =
                        value?.trim() ?? '';

                    if (v.isEmpty) {
                      return "Enter email";
                    }

                    if (!v.contains('@') ||
                        !v.contains('.')) {
                      return "Enter a valid email";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =================================================
                // PASSWORD
                // =================================================

                TextFormField(
                  controller: pass,
                  obscureText: hidePass,
                  decoration:
                  InputDecoration(
                    labelText: "Password",
                    border:
                    const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        hidePass
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePass =
                          !hidePass;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    final v =
                        value ?? '';

                    if (v.length < 6) {
                      return "Minimum 6 characters";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // =================================================
                // CONFIRM PASSWORD
                // =================================================

                TextFormField(
                  controller: confirm,
                  obscureText:
                  hideConfirm,
                  decoration:
                  InputDecoration(
                    labelText:
                    "Confirm Password",
                    border:
                    const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon:
                    IconButton(
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirm =
                          !hideConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    final v =
                        value ?? '';

                    if (v.isEmpty) {
                      return "Confirm your password";
                    }

                    if (v != pass.text) {
                      return "Passwords do not match";
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 30),

                // =================================================
                // SIGN UP BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                    loading
                        ? null
                        : signup,
                    child: loading
                        ? SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        color:
                        colorScheme
                            .onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      isMuftiInvite
                          ? "Join as Mufti"
                          : "Create Account",
                      style:
                      textTheme
                          .labelLarge
                          ?.copyWith(
                        fontSize: 16,
                        color:
                        colorScheme
                            .onPrimary,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // =================================================
                // LOGIN
                // =================================================

                TextButton(
                  onPressed: loading
                      ? null
                      : () =>
                      Navigator.pop(
                        context,
                      ),
                  child: const Text(
                    "Already have an account? Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}