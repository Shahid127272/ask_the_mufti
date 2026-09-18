import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/role_view_controller.dart';
import 'core/theme.dart';
import 'features/splash/splash_video_screen.dart';
import 'firebase_options.dart';
import 'providers/font_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';
import 'services/device_token_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.handleBackgroundMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await NotificationService.initialize(
    backgroundHandler: _firebaseMessagingBackgroundHandler,
  );
  String? token = await FirebaseMessaging.instance.getToken();

  debugPrint("=================================");
  debugPrint("FCM TOKEN = $token");
  debugPrint("=================================");

  /// 🔥 SAFE: try-catch added (kabhi crash na ho)
  try {
    await DeviceTokenService.startTokenSync();
  } catch (e) {
    debugPrint('DeviceTokenService error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => RoleViewController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FontProvider()..loadFonts(),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..loadTheme(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(),
          lazy: false,
        ),
      ],
      child: const AskTheMuftiApp(),
    ),
  );
}

class AskTheMuftiApp extends StatefulWidget {
  const AskTheMuftiApp({super.key});

  @override
  State<AskTheMuftiApp> createState() => _AskTheMuftiAppState();
}

class _AskTheMuftiAppState extends State<AskTheMuftiApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifProvider = context.read<NotificationProvider>();
      await notifProvider.loadSettings();
      notifProvider.start();

      NotificationService.consumePendingNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fonts = context.watch<FontProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final roleController = context.watch<RoleViewController>();

    final activeRole = roleController.activeRole.isEmpty
        ? 'user'
        : roleController.activeRole;

    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ask The Mufti',
      theme: AppTheme.lightForRole(activeRole),
      darkTheme: AppTheme.darkForRole(activeRole),
      themeMode: themeProvider.themeMode,
      home: const SplashVideoScreen(),
      routes: AppRoutes.routes,
      onUnknownRoute: AppRoutes.onUnknownRoute,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: DefaultTextStyle(
            style: TextStyle(fontFamily: fonts.uiFont),
            child: child ?? const SizedBox(),
          ),
        );
      },
    );
  }
}