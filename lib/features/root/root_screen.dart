import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/role_view_controller.dart';
import '../../services/user_service.dart';

import '../auth/account_setup_screen.dart';
import '../auth/login_screen.dart';
import '../home/main_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  bool _loading = true;

  StreamSubscription<User?>? _authSub;

  bool _setupRequired = false;

  @override
  void initState() {
    super.initState();

    _authSub = FirebaseAuth.instance
        .authStateChanges()
        .listen(_onAuthChanged);
  }

  // ============================================================
  // AUTH STATE
  // ============================================================

  Future<void> _onAuthChanged(User? user) async {
    if (!mounted) return;

    if (user == null) {
      setState(() {
        _loading = false;
        _setupRequired = false;
      });

      return;
    }

    await _loadUserData(user);
  }

  // ============================================================
  // LOAD + VERIFY USER
  // ============================================================

  Future<void> _loadUserData(User user) async {
    if (!mounted) return;

    setState(() {
      _loading = true;
    });

    try {
      // --------------------------------------------------------
      // Refresh Firebase Auth user
      // --------------------------------------------------------

      await user.reload();

      final freshUser =
          FirebaseAuth.instance.currentUser;

      if (freshUser == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _setupRequired = false;
        });

        return;
      }

      // --------------------------------------------------------
      // Create/update Firestore user
      // --------------------------------------------------------

      final userService = UserService();

      await userService.createUserIfNotExists(
        freshUser,
      );

      // --------------------------------------------------------
      // Get Firestore profile
      // --------------------------------------------------------

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(freshUser.uid)
          .get();

      final data = doc.data() ?? {};

      // --------------------------------------------------------
      // EMAIL VERIFICATION
      // --------------------------------------------------------

      final isGoogleUser =
      freshUser.providerData.any(
            (provider) =>
        provider.providerId == 'google.com',
      );

      final emailVerified =
          freshUser.emailVerified ||
              isGoogleUser;

      // --------------------------------------------------------
// PHONE VERIFICATION
// --------------------------------------------------------

      final phoneVerified =
          freshUser.providerData.any(
                (provider) =>
            provider.providerId == 'phone',
          ) &&
              freshUser.phoneNumber != null &&
              freshUser.phoneNumber!.trim().isNotEmpty;

// --------------------------------------------------------
// SCREEN NAME
// --------------------------------------------------------

      final screenName =
          data['screenName']
              ?.toString()
              .trim() ??
              '';

      final hasScreenName =
          screenName.length >= 3;

// --------------------------------------------------------
// FINAL PROFILE SETUP STATUS
// --------------------------------------------------------

      final setupCompleted =
          data['profileSetupCompleted'] == true;

// ========================================================
// IMPORTANT
//
// User can enter MainScreen ONLY when ALL are complete.
// ========================================================

      final profileReady =
          emailVerified &&
              phoneVerified &&
              hasScreenName &&
              setupCompleted;

      if (!mounted) return;

      setState(() {
        _setupRequired = !profileReady;
        _loading = false;
      });

// --------------------------------------------------------
// ROLE LISTENER
// --------------------------------------------------------

      if (profileReady) {
        context
            .read<RoleViewController>()
            .listenToRoleChanges();
      }
    } catch (e) {
      debugPrint(
        'ROOT USER LOAD ERROR: $e',
      );

      if (!mounted) return;

      // Safety:
      // Agar verification/profile status determine nahi ho saka,
      // user ko MainScreen me enter nahi karna dena.
      setState(() {
        _loading = false;
        _setupRequired = true;
      });
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    // ==========================================================
    // NOT LOGGED IN
    // ==========================================================

    if (user == null) {
      return const LoginScreen();
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ==========================================================
    // VERIFICATION / PROFILE SETUP REQUIRED
    // ==========================================================

    if (_setupRequired) {
      return const AccountSetupScreen();
    }

    // ==========================================================
    // ALL COMPLETE
    // ==========================================================

    return const MainScreen();
  }
}