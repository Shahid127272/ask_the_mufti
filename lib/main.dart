import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = AuthService();
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  runApp(const AskTheMuftiApp());
}

class AskTheMuftiApp extends StatelessWidget {
  const AskTheMuftiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ask The Mufti',
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}
