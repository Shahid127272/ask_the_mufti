import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../services/profile_service.dart';
import 'role_view_controller.dart';
import '../routes/app_routes.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleController = context.watch<RoleViewController>();
    final activeRole = roleController.activeRole;
    final roles = roleController.availableRoles;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: StreamBuilder<DocumentSnapshot>(
        stream: ProfileService().profileStream(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            );
          }

          Map<String, dynamic>? data;

          if (snapshot.hasData && snapshot.data!.data() != null) {
            data = snapshot.data!.data() as Map<String, dynamic>;
          }

          final name =
              data?["name"] ?? firebaseUser?.displayName ?? "User";

          final firestorePhoto = data?["photoUrl"];
          final photo = firestorePhoto ?? firebaseUser?.photoURL;

          return Column(
            children: [

              /// ✅ SIMPLE HEADER (NO CURVE)
              DrawerSimpleHeader(
                name: name,
                photo: photo,
                role: activeRole,
              ),

              const SizedBox(height: 20),

              /// ROLE SWITCH
              if (roles.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: Text(activeRole.toUpperCase()),
                  trailing: const Icon(Icons.keyboard_arrow_down),
                  onTap: () {
                    _showRoleSelector(
                      context,
                      roleController,
                      roles,
                      activeRole,
                    );
                  },
                ),

              const Divider(),

              /// MENU
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [

                    _item(
                      context,
                      icon: Icons.bookmark_border,
                      title: "Bookmarks",
                      route: AppRoutes.bookmarks,
                    ),

                    _item(
                      context,
                      icon: Icons.settings_outlined,
                      title: "Settings",
                      route: AppRoutes.settings,
                    ),

                    _item(
                      context,
                      icon: _panelIcon(activeRole),
                      title: "${activeRole.toUpperCase()} Panel",
                      route: _panelRoute(activeRole),
                    ),
                  ],
                ),
              ),

              const Divider(),

              /// LOGOUT
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.1),
                    foregroundColor: theme.colorScheme.primary,
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  onPressed: () async {

                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                          (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 15),
            ],
          );
        },
      ),
    );
  }

  /// ROLE SELECTOR
  void _showRoleSelector(
      BuildContext context,
      RoleViewController controller,
      List<String> roles,
      String activeRole,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: roles.map((r) {
            return ListTile(
              title: Text(r.toUpperCase()),
              trailing: r == activeRole
                  ? const Icon(Icons.check)
                  : null,
              onTap: () {
                controller.setRole(r);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _item(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String route,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: theme.iconTheme.color),
            const SizedBox(width: 12),
            Text(title, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  static String _panelRoute(String role) {
    switch (role) {
      case "owner":
      case "admin":
        return AppRoutes.adminDashboard;
      case "mufti":
        return AppRoutes.muftiPanel;
      default:
        return AppRoutes.home;
    }
  }

  static IconData _panelIcon(String role) {
    switch (role) {
      case 'owner':
        return Icons.workspace_premium;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'mufti':
        return Icons.menu_book;
      default:
        return Icons.dashboard;
    }
  }
}

/// ================= SIMPLE HEADER =================

class DrawerSimpleHeader extends StatelessWidget {

  final String name;
  final String? photo;
  final String role;

  const DrawerSimpleHeader({
    super.key,
    required this.name,
    this.photo,
    required this.role,
  });

  Future<void> _pickPhoto(BuildContext context) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final service = ProfileService();

    await service.updateProfile(name: '...');

    final XFile? picked =
    await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();

    await ProfileService().uploadProfilePhoto(file, fileName);
  }

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.primary,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),

      child: Row(
        children: [

          /// 👤 PROFILE + CAMERA
          GestureDetector(
            onTap: () => _pickPhoto(context),
            child: Stack(
              children: [

                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage:
                  photo != null ? NetworkImage(photo!) : null,
                  child: photo == null
                      ? const Icon(Icons.person, color: Colors.grey)
                      : null,
                ),

                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          /// 📝 NAME
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          /// ✏️ EDIT
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.editProfile,
              );
            },
          ),
        ],
      ),
    );
  }
}