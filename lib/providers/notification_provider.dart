import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider with ChangeNotifier {
  bool questionAlerts = true;
  bool answerAlerts = true;
  bool adminMessages = true;

  SharedPreferences? _prefs;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadSubscription;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  Future<void> loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    questionAlerts = _prefs?.getBool('question_alerts') ?? true;
    answerAlerts = _prefs?.getBool('answer_alerts') ?? true;
    adminMessages = _prefs?.getBool('admin_messages') ?? true;
    notifyListeners();
  }

  void start() {
    _authSubscription?.cancel();
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChanged,
    );
    _handleAuthChanged(FirebaseAuth.instance.currentUser);
  }

  void _handleAuthChanged(User? user) {
    _unreadSubscription?.cancel();

    debugPrint('=================================');
    debugPrint('AUTH UID = ${user?.uid}');
    debugPrint('AUTH EMAIL = ${user?.email}');
    debugPrint('=================================');

    if (user == null) {
      _unreadCount = 0;
      notifyListeners();
      return;
    }

    _unreadSubscription = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen(
          (snapshot) {
        _unreadCount = snapshot.docs.length;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('=================================');
        debugPrint('NOTIFICATION QUERY ERROR = $error');
        debugPrint('=================================');
      },
    );
  }

  Future<void> setQuestionAlerts(bool value) async {
    questionAlerts = value;
    await _prefs?.setBool('question_alerts', value);
    notifyListeners();
  }

  Future<void> setAnswerAlerts(bool value) async {
    answerAlerts = value;
    await _prefs?.setBool('answer_alerts', value);
    notifyListeners();
  }

  Future<void> setAdminMessages(bool value) async {
    adminMessages = value;
    await _prefs?.setBool('admin_messages', value);
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _unreadSubscription?.cancel();
    super.dispose();
  }
}
