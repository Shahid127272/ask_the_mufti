import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ❌ No anonymous / auto login here
  runApp(const AskTheMuftiApp());
}

class AskTheMuftiApp extends StatelessWidget {
  const AskTheMuftiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ask The Mufti',

      // ✅ Theme applied correctly
      theme: AppTheme.lightTheme,

      // 🔐 Auth / role redirect handled in RootScreen
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
