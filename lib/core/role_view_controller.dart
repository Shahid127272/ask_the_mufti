import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants.dart';
import '../services/user_service.dart';

class RoleViewController extends ChangeNotifier {
  final UserService _service = UserService();

  StreamSubscription<String>? _roleSub;
  StreamSubscription<User?>? _authSub;

  String _realRole = '';
  String _activeRole = '';
  bool _isLoading = true;

  String get realRole => _realRole;
  String get activeRole => _activeRole;
  bool get isLoading => _isLoading;

  bool get canSwitch =>
      _realRole.isNotEmpty && _realRole != AppConstants.roleUser;

  List<String> get availableRoles {
    switch (_realRole) {
      case AppConstants.roleOwner:
        return [
          AppConstants.roleOwner,
          AppConstants.roleAdmin,
          AppConstants.roleMufti,
          AppConstants.roleUser,
        ];
      case AppConstants.roleAdmin:
        return [
          AppConstants.roleAdmin,
          AppConstants.roleMufti,
          AppConstants.roleUser,
        ];
      case AppConstants.roleMufti:
        return [
          AppConstants.roleMufti,
          AppConstants.roleUser,
        ];
      default:
        return [AppConstants.roleUser];
    }
  }

  /// 🔥 START
  void start() {
    _authSub?.cancel();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _roleSub?.cancel();
        _realRole = '';
        _activeRole = '';
        _isLoading = false;
        notifyListeners();
      } else {
        _listen(user.uid);
      }
    });
  }

  /// 🔥 FIX (alias for old usage)
  void listenToRoleChanges() {
    start();
  }

  void _listen(String uid) {
    _roleSub?.cancel();

    _isLoading = true;
    notifyListeners();

    _roleSub = _service.watchUserRole(uid).listen(
          (newRole) {
        final role = newRole.trim().toLowerCase();

        if (role.isEmpty) return;

        _realRole = role;
        _isLoading = false;

        if (_activeRole.isEmpty) {
          _activeRole = role;
        }

        if (!availableRoles.contains(_activeRole)) {
          _activeRole = _realRole;
        }

        notifyListeners();
      },
      onError: (e) {
        _isLoading = false;
        _realRole = AppConstants.roleUser;
        _activeRole = AppConstants.roleUser;
        notifyListeners();
      },
    );
  }

  void setRole(String role) {
    final normalized = role.trim().toLowerCase();
    if (!availableRoles.contains(normalized)) return;
    if (_activeRole == normalized) return;
    _activeRole = normalized;
    notifyListeners();
  }

  void switchRole() {
    if (!canSwitch) return;

    final roles = availableRoles;
    final index = roles.indexOf(_activeRole);

    if (index == -1) {
      _activeRole = _realRole;
      notifyListeners();
      return;
    }

    _activeRole = roles[(index + 1) % roles.length];
    notifyListeners();
  }

  void resetRole() {
    _activeRole = _realRole;
    notifyListeners();
  }

  @override
  void dispose() {
    _roleSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}