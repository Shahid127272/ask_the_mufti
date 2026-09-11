import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_scaffold.dart';
import '../../services/auth_service.dart';
import '../../services/profile_service.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../donation/donation_form_screen.dart';
import 'edit_profile_screen.dart';
import 'my_questions_screen.dart';
import 'bookmarks_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ============================================================
  // PROFILE PHOTO
  // ============================================================

  Future<void> _pickPhoto(User user) async {
    try {
      final picker = ImagePicker();

      final XFile? picked = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      final file = File(picked.path);

      final fileName =
      DateTime.now().millisecondsSinceEpoch.toString();

      await ProfileService().uploadProfilePhoto(
        file,
        fileName,
      );
    } catch (e) {
      debugPrint('PROFILE PHOTO ERROR: $e');
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authState,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return AppScaffold(
          notificationCount: 0,
          body: user == null
              ? _buildLoggedOutUI(context)
              : _buildLoggedInUI(context, user),
        );
      },
    );
  }

  // ============================================================
  // LOGGED OUT
  // ============================================================

  Widget _buildLoggedOutUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey,
          ),

          const SizedBox(height: 24),

          const Text(
            'Please login to see your profile',
            style: TextStyle(
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
              );
            },
            child: const Text('Login'),
          ),

          const SizedBox(height: 12),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SignupScreen(),
                ),
              );
            },
            child: const Text('Create Account'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGGED IN
  // ============================================================

  Widget _buildLoggedInUI(
      BuildContext context,
      User user,
      ) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),

      builder: (context, snapshot) {
        final data = snapshot.data?.data();

        // Firestore ka Screen Name priority hoga.
        final firestoreScreenName =
        data?['screenName']
            ?.toString()
            .trim();

        final displayName =
        (firestoreScreenName != null &&
            firestoreScreenName.isNotEmpty)
            ? firestoreScreenName
            : (user.displayName != null &&
            user.displayName!.trim().isNotEmpty
            ? user.displayName!.trim()
            : 'User');

        final email =
            user.email ?? 'No email';

        final uid = user.uid;

        // Google user ke email ko verified maana jayega.
        final emailVerified =
            user.emailVerified ||
                user.providerData.any(
                      (provider) =>
                  provider.providerId ==
                      'google.com',
                );

        final phoneVerified =
            user.phoneNumber != null &&
                user.phoneNumber!.trim().isNotEmpty;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==================================================
            // PROFILE HEADER
            // ==================================================

            Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Row(
                  children: [
                    // PROFILE PHOTO
                    GestureDetector(
                      onTap: () => _pickPhoto(user),

                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 32,

                            backgroundImage:
                            user.photoURL != null
                                ? NetworkImage(
                              user.photoURL!,
                            )
                                : null,

                            child:
                            user.photoURL == null
                                ? const Icon(
                              Icons.person,
                              size: 36,
                            )
                                : null,
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,

                            child: Container(
                              decoration:
                              const BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                Color(0xFF0E7A5F),
                              ),

                              padding:
                              const EdgeInsets.all(4),

                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        overflow:
                                        TextOverflow
                                            .ellipsis,

                                        style:
                                        const TextStyle(
                                          fontSize: 18,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    if (emailVerified)
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),

                              IconButton(
                                icon:
                                const Icon(Icons.edit),

                                tooltip:
                                "Edit Profile",

                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                      const EditProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(email),

                          const SizedBox(height: 6),

                          // PHONE STATUS
                          Row(
                            children: [
                              Icon(
                                phoneVerified
                                    ? Icons.phone
                                    : Icons.phone_disabled,
                                size: 15,
                                color: phoneVerified
                                    ? Colors.green
                                    : Colors.grey,
                              ),

                              const SizedBox(width: 5),

                              Text(
                                phoneVerified
                                    ? 'Phone verified'
                                    : 'Phone not verified',

                                style: TextStyle(
                                  fontSize: 12,
                                  color: phoneVerified
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            "UID: $uid",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your activity will appear here',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // MY QUESTIONS
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.question_answer,
                ),

                title:
                const Text("My Questions"),

                subtitle: const Text(
                  "View questions you asked",
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const MyQuestionsScreen(),
                    ),
                  );
                },
              ),
            ),

            // ==================================================
            // BOOKMARKS
            // ==================================================

            Card(
              child: ListTile(
                leading:
                const Icon(Icons.bookmark),

                title:
                const Text("Bookmarks"),

                subtitle: const Text(
                  "Your saved answers",
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const BookmarksScreen(),
                    ),
                  );
                },
              ),
            ),

            // ==================================================
            // DONATION
            // ==================================================

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.volunteer_activism,
                ),

                title: const Text(
                  "Support / Donate",
                ),

                subtitle: const Text(
                  "Help keep this service running",
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const DonationFormScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 40),

            // ==================================================
            // LOGOUT
            // ==================================================

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),

                onPressed: () async {
                  if (!context.mounted) return;

                  // Prevent accidental double tap.
                  await AuthService().logout();

                  if (!context.mounted) return;

                  // Completely clear the current navigation
                  // stack and return to RootScreen.
                  //
                  // RootScreen will detect that Firebase user
                  // is null and show LoginScreen.
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(
                    '/',
                        (route) => false,
                  );
                },

                icon: const Icon(
                  Icons.logout,
                ),

                label: const Text(
                  'Logout',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}