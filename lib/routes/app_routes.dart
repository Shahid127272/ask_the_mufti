import 'package:flutter/material.dart';
import '../features/root/root_screen.dart';

class AppRoutes {
  static const home = '/';

  static final routes = <String, WidgetBuilder>{
    home: (_) => const RootScreen(),
  };
}
