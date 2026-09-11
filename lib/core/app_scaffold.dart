import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/role_view_controller.dart';
import '../features/notifications/notifications_screen.dart';
import '../providers/notification_provider.dart';

import 'app_drawer.dart';
import 'app_header.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final int notificationCount;

  const AppScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.notificationCount = 0,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final GlobalKey<ScaffoldState> scaffoldKey =
  GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleController =
    context.watch<RoleViewController>();

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      key: scaffoldKey,

      backgroundColor:
      theme.scaffoldBackgroundColor,

      drawer: const AppDrawer(),

      floatingActionButton:
      widget.floatingActionButton,

      floatingActionButtonLocation:
      FloatingActionButtonLocation
          .centerDocked,

      bottomNavigationBar:
      widget.bottomNavigationBar,

      body: Column(
        children: [

          Consumer<NotificationProvider>(
            builder: (_, notifProvider, __) {
              return AppHeader(
                userName:
                user?.displayName ?? "User",

                role:
                roleController.activeRole,

                profileImage:
                user?.photoURL,

                roleColor:
                theme.colorScheme.primary,

                notificationCount:
                notifProvider.unreadCount,

                onNotificationTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const NotificationsScreen(),
                    ),
                  );
                },

                onMenuTap: () {
                  scaffoldKey.currentState
                      ?.openDrawer();
                },
              );
            },
          ),

          Expanded(
            child: SafeArea(
              top: false,
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }
}