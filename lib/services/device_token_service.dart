import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'profile_service.dart';

class DeviceTokenService {
  final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final ProfileService _profileService =
  ProfileService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<User?>? _authSubscription;

  Future<void> init() async {
    // ------------------------------------------------
    // AUTH STATE LISTENER
    // ------------------------------------------------

    _authSubscription?.cancel();

    _authSubscription =
        _auth.authStateChanges().listen((user) async {
          if (user == null) return;

          await _saveCurrentToken();
        });

    // ------------------------------------------------
    // SAVE TOKEN IF USER IS ALREADY LOGGED IN
    // ------------------------------------------------

    await _saveCurrentToken();

    // ------------------------------------------------
    // TOKEN REFRESH LISTENER
    // ------------------------------------------------

    _tokenRefreshSubscription?.cancel();

    _tokenRefreshSubscription =
        _messaging.onTokenRefresh.listen((token) async {
          final user = _auth.currentUser;

          if (user == null) return;

          await _profileService.updateDeviceToken(token);
        });
  }

  Future<void> _saveCurrentToken() async {
    final user = _auth.currentUser;

    if (user == null) return;

    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) return;

    await _profileService.updateDeviceToken(token);
  }

  // ------------------------------------------------
  // START TOKEN SYNC
  // ------------------------------------------------

  static Future<void> startTokenSync() async {
    await DeviceTokenService().init();
  }
}