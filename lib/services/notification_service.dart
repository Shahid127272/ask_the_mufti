import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/answer_detail/answer_detail_screen.dart';
import '../features/notifications/notification_model.dart';
import '../features/notifications/notifications_screen.dart';
import '../firebase_options.dart';
import '../models/question_model.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'ask_mufti_channel',
    'Ask The Mufti Notifications',
    description: 'Notifications for questions and answers',
    importance: Importance.high,
  );

  static bool _initialized = false;
  static Map<String, dynamic>? _pendingNavigationData;

  static Future<void> initialize({
    required BackgroundMessageHandler backgroundHandler,
  }) async {
    if (_initialized) return;

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      provisional: false,
      criticalAlert: false,
    );

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(backgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            handleNavigation(decoded);
          } else if (decoded is Map) {
            handleNavigation(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          handleNavigation({});
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen((message) async {
      await processIncomingMessage(
        message,
        persistIfPossible: true,
        showLocalNotification: true,
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) async {
      await processIncomingMessage(
        message,
        persistIfPossible: true,
        showLocalNotification: false,
      );
      handleNavigation(message.data);
    });

    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      await processIncomingMessage(
        initialMessage,
        persistIfPossible: true,
        showLocalNotification: false,
      );
      _pendingNavigationData = Map<String, dynamic>.from(initialMessage.data);
    }

    _initialized = true;
  }

  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (error) {
      debugPrint('Background Firebase init failed: $error');
    }

    await processIncomingMessage(
      message,
      persistIfPossible: true,
      showLocalNotification: false,
    );
  }

  static Future<void> processIncomingMessage(
    RemoteMessage message, {
    required bool persistIfPossible,
    required bool showLocalNotification,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final type = message.data['type']?.toString() ?? '';

    final questionAlerts = prefs.getBool('question_alerts') ?? true;
    final answerAlerts = prefs.getBool('answer_alerts') ?? true;
    final adminMessages = prefs.getBool('admin_messages') ?? true;

    if (type == 'question' && !questionAlerts) return;
    if (type == 'answer' && !answerAlerts) return;
    if (type == 'admin' && !adminMessages) return;

    if (persistIfPossible) {
      await _persistMessage(message);
    }

    if (!showLocalNotification) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString() ?? 'Notification';
    final body = notification?.body ?? message.data['body']?.toString() ?? '';

    await _showNotification(title, body, message.data);
  }

  static Future<void> _persistMessage(RemoteMessage message) async {
    final userId = _resolveTargetUserId(message.data);
    if (userId == null || userId.isEmpty) return;

    final notification = message.notification;
    final docId = message.data['notificationId']?.toString() ??
        message.messageId ??
        '${userId}_${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .set({
        'userId': userId,
        'title': notification?.title ?? message.data['title']?.toString() ?? '',
        'message': notification?.body ?? message.data['body']?.toString() ?? '',
        'time': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': message.data['type']?.toString() ?? 'general',
        'questionId': message.data['questionId']?.toString(),
        'route': message.data['route']?.toString(),
        'messageId': message.messageId ?? docId,
        'notificationId': docId,
      }, SetOptions(merge: true));
    } catch (error) {
      debugPrint('Notification persistence failed: $error');
    }
  }

  static String? _resolveTargetUserId(Map<String, dynamic> data) {
    return data['userId']?.toString() ?? FirebaseAuth.instance.currentUser?.uid;
  }

  static Future<void> handleNotificationTap(NotificationModel notification) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(notification.id)
        .set({'isRead': true}, SetOptions(merge: true));

    handleNavigation({
      'type': notification.type,
      'questionId': notification.questionId,
      'route': notification.route,
    });
  }

  static void consumePendingNavigation() {
    if (_pendingNavigationData == null) return;
    final data = Map<String, dynamic>.from(_pendingNavigationData!);
    _pendingNavigationData = null;
    handleNavigation(data);
  }

  static void handleNavigation(Map<String, dynamic> data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      _pendingNavigationData = data;
      return;
    }

    final type = data['type']?.toString();
    final route = data['route']?.toString();
    final questionId = data['questionId']?.toString();

    if (questionId != null && questionId.isNotEmpty && type == 'answer') {
      _openAnswerDetail(questionId);
      return;
    }

    if (route == '/notifications' || type == 'admin') {
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }

    navigator.pushNamed('/notifications');
  }

  static Future<void> _openAnswerDetail(String questionId) async {
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) {
      _pendingNavigationData = {
        'type': 'answer',
        'questionId': questionId,
      };
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('questions')
        .doc(questionId)
        .get();

    if (!doc.exists) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      );
      return;
    }

    final question = QuestionModel.fromFirestore(doc);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => AnswerDetailScreen(question: question),
      ),
    );
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    await _showNotification(title, body, data);
  }

  static Future<void> _showNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'ask_mufti_channel',
      'Ask The Mufti Notifications',
      channelDescription: 'Notifications for questions and answers',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  static Future<String?> getDeviceToken() async {
    return _firebaseMessaging.getToken();
  }
}
