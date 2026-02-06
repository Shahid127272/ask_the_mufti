import 'package:flutter/material.dart';
import '../../core/services/user_role_service.dart';

import '../feeds/feeds_screen.dart';
import '../categories/categories_screen.dart';
import '../ask_question/ask_question_screen.dart';
import '../profile/profile_screen.dart';
import '../mufti/mufti_dashboard_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await UserRoleService().getCurrentUserRole();

    if (!mounted) return;

    setState(() {
      _role = role ?? 'user';
      _index = 0; // ✅ safety reset
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
    final base = <Widget>[
      const FeedsScreen(),
      const CategoriesScreen(),
      const AskQuestionScreen(),
    ];

    if (role == 'mufti' || role == 'owner') {
      base.add(const MuftiDashboardScreen());
    }

    base.add(const ProfileScreen());
    return base;
  }

  // 🔑 ROLE → NAV ITEMS
  List<BottomNavigationBarItem> _itemsByRole(String role) {
    final base = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Feeds',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.category),
        label: 'Categories',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_circle_outline),
        label: 'Ask',
      ),
    ];

    if (role == 'mufti' || role == 'owner') {
      base.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Mufti',
        ),
      );
    }

    base.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profile',
      ),
    );

    return base;
  }
}
