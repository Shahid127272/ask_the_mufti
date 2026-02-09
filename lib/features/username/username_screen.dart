import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/username_service.dart';

class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final _controller = TextEditingController();
  final _service = UsernameService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 🔍 BASIC VALIDATION
  String? _validate(String value) {
    final username = value.trim().toLowerCase();

    if (username.isEmpty) {
      return 'Username required';
    }

    if (username.contains(' ')) {
      return 'Spaces not allowed';
    }

    if (username.length < 4) {
      return 'Minimum 4 characters';
    }

    return null;
  }

  Future<void> _submit() async {
    final raw = _controller.text;
    final validationError = _validate(raw);

    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }

    final username = raw.trim().toLowerCase();
    final user = FirebaseAuth.instance.currentUser!;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final available = await _service.isUsernameAvailable(username);

      if (!available) {
        setState(() {
          _error = 'Username already taken';
          _loading = false;
        });
        return;
      }

      await _service.setUsername(
        uid: user.uid,
        username: username,
      );

      if (!mounted) return;

      // ✅ RootScreen will auto-continue
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = 'Something went wrong';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Username'),
        automaticallyImplyLeading: false, // ⛔ no back
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pick a unique username',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'This will be visible publicly',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            TextField(
              controller: _controller,
              textInputAction: TextInputAction.done,
              enabled: !_loading,
              decoration: InputDecoration(
                hintText: 'e.g. mufti_ahmad',
                prefixIcon: const Icon(Icons.person),
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
