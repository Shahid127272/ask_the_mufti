import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final pass = TextEditingController();
  final confirm = TextEditingController();

  final AuthService _auth = AuthService();

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

    setState(() => loading = true);

    final error = await _auth.signUp(
      email: email.text.trim(),
      password: pass.text,
      // Screen Name abhi nahi lenge.
      displayName: '',
    );

    if (!mounted) return;

    setState(() => loading = false);

    if (error != null) {
      _show(error, error: true);
      return;
    }

    // AuthState change ke through RootScreen
    // AccountSetupScreen par le jayega.
    _show(
      'Account created. Please verify your email.',
    );

    Navigator.of(context).pop();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _show(
      String message, {
        bool error = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
          error ? Colors.red : Colors.green,
        ),
      );
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.person_add_alt_1,
                  size: 65,
                ),

                const SizedBox(height: 20),

                const Text(
                  "Create your Ask The Mufti account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Create your account, complete verification, "
                      "then choose your Screen Name.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
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
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    final v = value?.trim() ?? '';

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
                  decoration: InputDecoration(
                    labelText: "Password",
                    border: const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hidePass
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hidePass = !hidePass;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';

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
                  obscureText: hideConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm Password",
                    border: const OutlineInputBorder(),
                    prefixIcon:
                    const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        hideConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          hideConfirm = !hideConfirm;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    final v = value ?? '';

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
                    loading ? null : signup,
                    child: loading
                        ? const SizedBox(
                      height: 22,
                      width: 22,
                      child:
                      CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                        : const Text(
                      "Create Account",
                      style: TextStyle(
                        fontSize: 16,
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
                      : () => Navigator.pop(context),
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