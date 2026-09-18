import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/answer_detail/answer_detail_screen.dart';
import '../features/notifications/notification_detail_screen.dart';
import '../features/notifications/notification_model.dart';
import '../features/notifications/notifications_screen.dart';
import '../firebase_options.dart';
import '../models/question_model.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static final FlutterLocalNotificationsPlugin
  _localNotifications =
  FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static const AndroidNotificationChannel _channel =
  AndroidNotificationChannel(
    'ask_mufti_channel',
    'Ask The Mufti Notifications',
    description:
    'Notifications for questions and answers',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  static bool _initialized = false;

  static Map<String, dynamic>? _pendingNavigationData;

  // =========================================================
  // INITIALIZE
  // =========================================================

  static Future<void> initialize({
    required BackgroundMessageHandler backgroundHandler,
  }) async {
    if (_initialized) return;

    // =======================================================
    // FIREBASE NOTIFICATION PERMISSION
    // =======================================================

    final permissionSettings =
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      provisional: false,
      criticalAlert: false,
    );

    debugPrint(
      'FCM AUTHORIZATION STATUS = '
          '${permissionSettings.authorizationStatus}',
    );

    await _firebaseMessaging
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // =======================================================
    // BACKGROUND MESSAGE HANDLER
    // =======================================================

    FirebaseMessaging.onBackgroundMessage(
      backgroundHandler,
    );

    // =======================================================
    // LOCAL NOTIFICATIONS INITIALIZATION
    // =======================================================

    const androidInit =
    AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (response) async {
        final payload = response.payload;

        if (payload == null ||
            payload.isEmpty) {
          return;
        }

        try {
          final decoded =
          jsonDecode(payload);

          if (decoded
          is Map<String, dynamic>) {
            await _handleLocalNotificationTap(
              decoded,
            );
          } else if (decoded is Map) {
            await _handleLocalNotificationTap(
              Map<String, dynamic>.from(
                decoded,
              ),
            );
          }
        } catch (error) {
          debugPrint(
            'Notification payload decode failed: '
                '$error',
          );

          handleNavigation({});
        }
      },
    );

    // =======================================================
    // ANDROID NOTIFICATION CHANNEL
    // =======================================================

    final androidPlugin =
    _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin
        ?.createNotificationChannel(
      _channel,
    );

    // Android 13+
    await androidPlugin
        ?.requestNotificationsPermission();

    // =======================================================
    // FOREGROUND MESSAGE
    // =======================================================

    FirebaseMessaging.onMessage.listen(
          (message) async {
        debugPrint(
          '=================================',
        );
        debugPrint(
          'FCM FOREGROUND MESSAGE RECEIVED',
        );
        debugPrint(
          'MESSAGE ID = ${message.messageId}',
        );
        debugPrint(
          'DATA = ${message.data}',
        );
        debugPrint(
          '=================================',
        );

        await processIncomingMessage(
          message,
          persistIfPossible: true,
          showLocalNotification: true,
        );
      },
    );

    // =======================================================
    // NOTIFICATION OPENED FROM BACKGROUND
    // =======================================================

    FirebaseMessaging.onMessageOpenedApp.listen(
          (message) async {
        debugPrint(
          '=================================',
        );
        debugPrint(
          'FCM NOTIFICATION OPENED',
        );
        debugPrint(
          'MESSAGE ID = ${message.messageId}',
        );
        debugPrint(
          'DATA = ${message.data}',
        );
        debugPrint(
          '=================================',
        );

        await processIncomingMessage(
          message,
          persistIfPossible: true,
          showLocalNotification: false,
        );

        handleNavigation(
          Map<String, dynamic>.from(
            message.data,
          ),
        );
      },
    );

    // =======================================================
    // NOTIFICATION OPENED FROM TERMINATED APP
    // =======================================================

    final initialMessage =
    await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      debugPrint(
        '=================================',
      );
      debugPrint(
        'FCM INITIAL MESSAGE RECEIVED',
      );
      debugPrint(
        'MESSAGE ID = '
            '${initialMessage.messageId}',
      );
      debugPrint(
        'DATA = ${initialMessage.data}',
      );
      debugPrint(
        '=================================',
      );

      await processIncomingMessage(
        initialMessage,
        persistIfPossible: true,
        showLocalNotification: false,
      );

      _pendingNavigationData =
      Map<String, dynamic>.from(
        initialMessage.data,
      );
    }

    _initialized = true;

    debugPrint(
      'NotificationService initialized successfully.',
    );
  }

  // =========================================================
  // BACKGROUND MESSAGE
  // =========================================================

  static Future<void> handleBackgroundMessage(
      RemoteMessage message,
      ) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options:
          DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (error) {
      debugPrint(
        'Background Firebase init failed: '
            '$error',
      );
    }

    debugPrint(
      '=================================',
    );
    debugPrint(
      'FCM BACKGROUND MESSAGE RECEIVED',
    );
    debugPrint(
      'MESSAGE ID = ${message.messageId}',
    );
    debugPrint(
      'DATA = ${message.data}',
    );
    debugPrint(
      '=================================',
    );

    await processIncomingMessage(
      message,
      persistIfPossible: true,
      showLocalNotification: false,
    );
  }

  // =========================================================
  // PROCESS INCOMING MESSAGE
  // =========================================================

  static Future<void> processIncomingMessage(
      RemoteMessage message, {
        required bool persistIfPossible,
        required bool showLocalNotification,
      }) async {
    final prefs =
    await SharedPreferences.getInstance();

    final type =
        message.data['type']?.toString() ?? '';

    final questionAlerts =
        prefs.getBool('question_alerts') ??
            true;

    final answerAlerts =
        prefs.getBool('answer_alerts') ??
            true;

    final adminMessages =
        prefs.getBool('admin_messages') ??
            true;

    if (type == 'question' &&
        !questionAlerts) {
      return;
    }

    if (type == 'answer' &&
        !answerAlerts) {
      return;
    }

    if (type == 'admin' &&
        !adminMessages) {
      return;
    }

    if (persistIfPossible) {
      await _persistMessage(message);
    }

    if (!showLocalNotification) {
      return;
    }

    final notification =
        message.notification;

    final title =
        notification?.title ??
            message.data['title']
                ?.toString() ??
            'Notification';

    final body =
        notification?.body ??
            message.data['body']
                ?.toString() ??
            '';

    await _showNotification(
      title,
      body,
      message.data,
    );
  }

  // =========================================================
  // SAVE NOTIFICATION TO FIRESTORE
  // =========================================================

  static Future<void> _persistMessage(
      RemoteMessage message,
      ) async {
    final userId =
    _resolveTargetUserId(
      message.data,
    );

    if (userId == null ||
        userId.isEmpty) {
      return;
    }

    final notification =
        message.notification;

    final docId =
        message.data['notificationId']
            ?.toString() ??
            message.messageId ??
            '${userId}_'
                '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}';

    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .set(
        {
          'userId': userId,
          'title':
          notification?.title ??
              message.data['title']
                  ?.toString() ??
              '',
          'message':
          notification?.body ??
              message.data['body']
                  ?.toString() ??
              '',
          'time':
          FieldValue.serverTimestamp(),
          'isRead': false,
          'type':
          message.data['type']
              ?.toString() ??
              'general',
          'questionId':
          message.data['questionId']
              ?.toString(),
          'route':
          message.data['route']
              ?.toString(),
          'messageId':
          message.messageId ?? docId,
          'notificationId': docId,
        },
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint(
        'Notification persistence failed: '
            '$error',
      );
    }
  }

  // =========================================================
  // RESOLVE TARGET USER
  // =========================================================

  static String? _resolveTargetUserId(
      Map<String, dynamic> data,
      ) {
    return data['userId']?.toString() ??
        FirebaseAuth.instance.currentUser?.uid;
  }

  // =========================================================
  // NOTIFICATION TAP FROM NOTIFICATION LIST
  // =========================================================

  static Future<void> handleNotificationTap(
      NotificationModel notification,
      ) async {
    // Notification ko read mark karo.
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notification.id)
          .set(
        {'isRead': true},
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint(
        'Notification read update failed: '
            '$error',
      );
    }

    // -------------------------------------------------------
    // IMPORTANT:
    // Har notification ka full message pehle open hoga.
    // Answer notification ke andar "Open Answer" button
    // available rahega.
    // -------------------------------------------------------

    await _openNotificationDetail(
      notification,
    );
  }

  // =========================================================
  // OPEN NOTIFICATION DETAIL
  // =========================================================

  static Future<void> _openNotificationDetail(
      NotificationModel notification,
      ) async {
    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      _pendingNavigationData = {
        'type': 'notification',
        'notificationId':
        notification.id,
      };

      return;
    }

    await navigator.push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationDetailScreen(
              notification: notification,
            ),
      ),
    );
  }

  // =========================================================
  // LOCAL NOTIFICATION TAP
  // =========================================================

  static Future<void>
  _handleLocalNotificationTap(
      Map<String, dynamic> data,
      ) async {
    final type =
    data['type']?.toString();

    final questionId =
    data['questionId']?.toString();

    final notificationId =
    data['notificationId']?.toString();

    // -------------------------------------------------------
    // Agar Firestore notification ID available hai,
    // to actual saved notification open karo.
    // -------------------------------------------------------

    if (notificationId != null &&
        notificationId.isNotEmpty) {
      final doc =
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (doc.exists) {
        final notification =
        NotificationModel
            .fromFirestore(doc);

        await handleNotificationTap(
          notification,
        );

        return;
      }
    }

    // -------------------------------------------------------
    // Agar notification Firestore mein nahi mili,
    // to direct navigation fallback.
    // -------------------------------------------------------

    handleNavigation({
      'type': type,
      'questionId': questionId,
      'route':
      data['route']?.toString(),
    });
  }

  // =========================================================
  // PENDING NAVIGATION
  // =========================================================

  static void consumePendingNavigation() {
    if (_pendingNavigationData ==
        null) {
      return;
    }

    final data =
    Map<String, dynamic>.from(
      _pendingNavigationData!,
    );

    _pendingNavigationData = null;

    handleNavigation(data);
  }

  // =========================================================
  // NAVIGATION
  // =========================================================

  static void handleNavigation(
      Map<String, dynamic> data,
      ) {
    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      _pendingNavigationData = data;
      return;
    }

    final type =
    data['type']?.toString();

    final route =
    data['route']?.toString();

    final questionId =
    data['questionId']?.toString();

    final notificationId =
    data['notificationId']
        ?.toString();

    // -------------------------------------------------------
    // If this is a saved notification and we have its ID,
    // open the complete notification message.
    // -------------------------------------------------------

    if (notificationId != null &&
        notificationId.isNotEmpty) {
      _openNotificationById(
        notificationId,
      );

      return;
    }

    // -------------------------------------------------------
    // Answer notification with question ID
    // -------------------------------------------------------

    if (questionId != null &&
        questionId.isNotEmpty &&
        (type == 'answer' ||
            route == '/answerDetail')) {
      _openAnswerDetail(
        questionId,
      );

      return;
    }

    // -------------------------------------------------------
    // Notification screen
    // -------------------------------------------------------

    if (route == '/notifications' ||
        type == 'admin' ||
        type == 'question' ||
        type == 'notification') {
      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
          const NotificationsScreen(),
        ),
      );

      return;
    }

    navigator.pushNamed(
      '/notifications',
    );
  }

  // =========================================================
  // OPEN NOTIFICATION BY ID
  // =========================================================

  static Future<void>
  _openNotificationById(
      String notificationId,
      ) async {
    final navigator =
        navigatorKey.currentState;

    if (navigator == null) {
      _pendingNavigationData = {
        'type': 'notification',
        'notificationId':
        notificationId,
      };

      return;
    }

    try {
      final doc =
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .get();

      if (!doc.exists) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
            const NotificationsScreen(),
          ),
        );

        return;
      }

      final notification =
      NotificationModel.fromFirestore(
        doc,
      );

      await handleNotificationTap(
        notification,
      );
    } catch (error) {
      debugPrint(
        'Opening notification failed: '
            '$error',
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
          const NotificationsScreen(),
        ),
      );
    }
  }

  // =========================================================
  // OPEN ANSWER FROM NOTIFICATION DETAIL
  // =========================================================

  static Future<void>
  openAnswerFromNotification(
      String questionId,
      ) async {
    await _openAnswerDetail(
      questionId,
    );
  }

  // =========================================================
  // OPEN ANSWER DETAIL
  // =========================================================

  static Future<void> _openAnswerDetail(
      String questionId,
      ) async {
    final navigator =
        navigatorKey.currentState;

    final context =
        navigatorKey.currentContext;

    if (navigator == null ||
        context == null) {
      _pendingNavigationData = {
        'type': 'answer',
        'questionId': questionId,
      };

      return;
    }

    try {
      final doc =
      await FirebaseFirestore.instance
          .collection('questions')
          .doc(questionId)
          .get();

      if (!doc.exists) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
            const NotificationsScreen(),
          ),
        );

        return;
      }

      final question =
      QuestionModel.fromFirestore(
        doc,
      );

      await navigator.push(
        MaterialPageRoute(
          builder: (_) =>
              AnswerDetailScreen(
                question: question,
              ),
        ),
      );
    } catch (error) {
      debugPrint(
        'Opening answer detail failed: '
            '$error',
      );

      navigator.push(
        MaterialPageRoute(
          builder: (_) =>
          const NotificationsScreen(),
        ),
      );
    }
  }

  // =========================================================
  // PUBLIC SHOW NOTIFICATION
  // =========================================================

  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic> data =
    const {},
  }) async {
    await _showNotification(
      title,
      body,
      data,
    );
  }

  // =========================================================
  // SHOW LOCAL NOTIFICATION
  // =========================================================

  static Future<void> _showNotification(
      String title,
      String body,
      Map<String, dynamic> data,
      ) async {
    const androidDetails =
    AndroidNotificationDetails(
      'ask_mufti_channel',
      'Ask The Mufti Notifications',
      channelDescription:
      'Notifications for questions and answers',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/launcher_icon',
    );

    const details =
    NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      DateTime.now()
          .millisecondsSinceEpoch ~/
          1000,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  // =========================================================
  // DEVICE TOKEN
  // =========================================================

  static Future<String?>
  getDeviceToken() async {
    return _firebaseMessaging
        .getToken();
  }
}