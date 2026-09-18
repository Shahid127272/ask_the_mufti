import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String userName;
  final String role;
  final String? profileImage;
  final Color roleColor;

  final int notificationCount;

  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const AppHeader({
    super.key,
    required this.userName,
    required this.role,
    this.profileImage,
    required this.roleColor,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);

    return Material(
      color: roleColor,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          height: media.size.height * 0.11,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              /// PROFILE
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage:
                (profileImage != null && profileImage!.isNotEmpty)
                    ? NetworkImage(profileImage!)
                    : null,
                onBackgroundImageError: (_, __) {},
                child: (profileImage == null || profileImage!.isEmpty)
                    ? Icon(
                  Icons.person,
                  color: theme.colorScheme.onSurface
                      .withValues(alpha: 0.55),
                )
                    : null,
              ),

              const SizedBox(width: 12),

              /// NAME
              Expanded(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: const TextScaler.linear(1.1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              /// ROLE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              /// NOTIFICATION
              Stack(
                children: [
                  IconButton(
                    onPressed: onNotificationTap ?? () {},
                    splashRadius: 22,
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),

                  if (notificationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationCount > 99
                              ? "99+"
                              : notificationCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),

              /// MENU
              Builder(
                builder: (context) => IconButton(
                  splashRadius: 22,
                  onPressed: onMenuTap ??
                          () {
                        Scaffold.of(context).openDrawer();
                      },
                  icon: const Icon(
                    Icons.menu,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}