import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/phone_login_screen.dart';
import '../features/root/root_screen.dart';

class AppRoutes {
  static const home = '/';

  static Map<String, WidgetBuilder> routes = {
    '/': (_) => const RootScreen(),
    '/login': (_) => const LoginScreen(),
    '/phone-login': (_) => const PhoneLoginScreen(),
  };
}
