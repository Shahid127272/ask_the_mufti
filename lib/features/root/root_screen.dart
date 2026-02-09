import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/role_service.dart';
import '../../services/user_service.dart';
import '../../services/username_service.dart';

import '../auth/login_screen.dart';
import '../feeds/feeds_screen.dart';
import '../categories/categories_screen.dart';
import '../ask_question/ask_question_screen.dart';
import '../profile/profile_screen.dart';
import '../mufti/mufti_dashboard_screen.dart';
import '../username/username_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  String? _role;
  String? _username;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    /// 🔐 Auth state listener (login / logout safe)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _role = null;
          _username = null;
          _index = 0;
          _loading = false;
        });
      } else {
        _loadUserData();
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);

    final user = FirebaseAuth.instance.currentUser!;
    final userService = UserService();
    final usernameService = UsernameService();

    /// ensure user doc exists
    await userService.createUserIfNotExists(user);

    final role = await RoleService().getCurrentUserRole();
    final username = await usernameService.getUsername(user.uid);

    if (!mounted) return;

    setState(() {
      _role = role;
      _username = username;
      _index = 0;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    /// 🔐 LOGIN GATE
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginScreen();
    }

    /// ⏳ LOADING
    if (_loading || _role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    /// 🧑 USERNAME REQUIRED
    if (_username == null) {
      return const UsernameScreen();
    }

    final screens = _screensByRole(_role!);
    final items = _itemsByRole(_role!);

    return Scaffold(
      body: screens[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _index = i),
        items: items,
      ),
    );
  }

  // 🔑 ROLE → SCREENS
  List<Widget> _screensByRole(String role) {
    final List<Widget> base = [
      FeedsScreen(), // ❗ not const
      const CategoriesScreen(),
      const AskQuestionScreen(),
    ];

    if (role == 'admin' || role == 'mufti') {
      base.add(const MuftiDashboardScreen());
    }

    base.add(const ProfileScreen());
    return base;
  }

  // 🔑 ROLE → NAV ITEMS
  List<BottomNavigationBarItem> _itemsByRole(String role) {
    final List<BottomNavigationBarItem> items = const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Feeds',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.category),
        label: 'Categories',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        label: 'Ask',
      ),
    ].toList();

    if (role == 'admin' || role == 'mufti') {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Mufti',
        ),
      );
    }

    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    );

    return items;
  }
}
