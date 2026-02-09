import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    scaffoldBackgroundColor: const Color(0xFFF7F8FC),
    primaryColor: const Color(0xFF4A5D73),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F8FC),
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Color(0xFF1F2933)),
      titleTextStyle: TextStyle(
        color: Color(0xFF1F2933),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF4A5D73),
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Color(0xFF1F2933),
      ),
    ),
  );
}
