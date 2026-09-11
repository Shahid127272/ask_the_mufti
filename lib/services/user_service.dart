import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../core/constants.dart';
import '../models/app_user.dart';

class UserService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  String? get uid => _auth.currentUser?.uid;

  // ============================================================
  // DEFAULT NAME
  // ============================================================

  String _generateDefaultName(User user) {
    if (user.displayName != null &&
        user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    if (user.email != null &&
        user.email!.contains('@')) {
      return user.email!.split('@').first;
    }

    if (user.phoneNumber != null &&
        user.phoneNumber!.length >= 4) {
      return 'User${user.phoneNumber!.substring(
        user.phoneNumber!.length - 4,
      )}';
    }

    return 'User';
  }

  // ============================================================
  // EMAIL VERIFIED
  // ============================================================

  bool _isEmailVerified(User user) {
    final isGoogleUser = user.providerData.any(
          (provider) =>
      provider.providerId == 'google.com',
    );

    return user.emailVerified || isGoogleUser;
  }

  // ============================================================
  // PHONE VERIFIED
  // ============================================================

  bool _isPhoneVerified(User user) {
    return user.phoneNumber != null &&
        user.phoneNumber!.trim().isNotEmpty;
  }

  // ============================================================
  // CREATE USER IF NOT EXISTS
  //
  // IMPORTANT:
  // Existing UID / role / screenName preserve honge.
  // ============================================================

  Future<void> createUserIfNotExists(
      User user,
      ) async {
    final ref = _db
        .collection(AppConstants.usersCollection)
        .doc(user.uid);

    final snap = await ref.get(
      const GetOptions(source: Source.server),
    );

    // ==========================================================
    // EXISTING USER
    // ==========================================================

    if (snap.exists) {
      final data =
          snap.data() ?? <String, dynamic>{};

      final updates =
      <String, dynamic>{
        'uid': user.uid,

        AppConstants.fieldEmail:
        user.email,

        'phone':
        user.phoneNumber,

        'emailVerified':
        _isEmailVerified(user),

        'phoneVerified':
        _isPhoneVerified(user),

        AppConstants.fieldUpdatedAt:
        FieldValue.serverTimestamp(),
      };

      // --------------------------------------------------------
      // Screen name kabhi overwrite nahi karna.
      // --------------------------------------------------------

      final existingScreenName =
          data['screenName']
              ?.toString()
              .trim() ??
              '';

      if (existingScreenName.isEmpty) {
        updates['screenName'] = '';
      }

      // --------------------------------------------------------
      // Old name field missing ho to fallback.
      // --------------------------------------------------------

      final existingName =
          data['name']
              ?.toString()
              .trim() ??
              '';

      if (existingName.isEmpty) {
        updates['name'] =
            _generateDefaultName(user);
      }

      // --------------------------------------------------------
      // Old users ke liye missing setup field.
      // --------------------------------------------------------

      if (!data.containsKey(
        'profileSetupCompleted',
      )) {
        updates['profileSetupCompleted'] =
        false;
      }

      // --------------------------------------------------------
      // Role missing ho to only then user.
      // Existing role ko touch nahi karna.
      // --------------------------------------------------------

      if (!data.containsKey(
        AppConstants.fieldRole,
      )) {
        updates[AppConstants.fieldRole] =
            AppConstants.roleUser;
      }

      await ref.set(
        updates,
        SetOptions(merge: true),
      );

      return;
    }

    // ==========================================================
    // NEW USER
    // ==========================================================

    String role = AppConstants.roleUser;

    // ==========================================================
    // INVITE SUPPORT
    // ==========================================================

    if (user.email != null &&
        user.email!.trim().isNotEmpty) {
      final email =
      user.email!.trim().toLowerCase();

      final inviteSnap = await _db
          .collection(
        AppConstants.invitationsCollection,
      )
          .where(
        AppConstants.fieldEmail,
        isEqualTo: email,
      )
          .where(
        AppConstants.fieldStatus,
        isEqualTo:
        AppConstants.inviteStatusPending,
      )
          .limit(1)
          .get();

      if (inviteSnap.docs.isNotEmpty) {
        final invite =
            inviteSnap.docs.first;

        final invitedRole =
        invite.data()[
        AppConstants.fieldRole
        ];

        if (invitedRole is String &&
            AppConstants.allRoles
                .contains(
              invitedRole
                  .trim()
                  .toLowerCase(),
            )) {
          role =
              invitedRole.trim().toLowerCase();
        }

        await _db
            .collection(
          AppConstants.invitationsCollection,
        )
            .doc(invite.id)
            .update({
          AppConstants.fieldStatus:
          AppConstants.inviteStatusAccepted,
        });
      }
    }

    final defaultName =
    _generateDefaultName(user);

    // ==========================================================
    // IMPORTANT
    //
    // New user ka screenName EMPTY rahega.
    // AccountSetupScreen user se actual Screen Name lega.
    // ==========================================================

    await ref.set({
      'uid': user.uid,

      AppConstants.fieldEmail:
      user.email,

      'phone':
      user.phoneNumber,

      AppConstants.fieldDisplayName:
      defaultName,

      // New screen-name system.
      'screenName': '',

      // Compatibility with old system.
      'name': defaultName,

      AppConstants.fieldPhotoUrl:
      user.photoURL,

      AppConstants.fieldRole:
      role,

      'emailVerified':
      _isEmailVerified(user),

      'phoneVerified':
      _isPhoneVerified(user),

      // User must complete onboarding.
      'profileSetupCompleted':
      false,

      AppConstants.fieldCreatedAt:
      FieldValue.serverTimestamp(),

      AppConstants.fieldUpdatedAt:
      FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // COMPLETE PROFILE SETUP
  // ============================================================

  Future<void> completeProfileSetup({
    required String screenName,
  }) async {
    final currentUid = uid;

    if (currentUid == null) {
      throw Exception(
        'User not logged in.',
      );
    }

    final cleanName =
    screenName.trim();

    if (cleanName.length < 3) {
      throw Exception(
        'Screen name must contain at least 3 characters.',
      );
    }

    final user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'User session not found.',
      );
    }

    // Refresh Firebase user.
    await user.reload();

    final freshUser =
        _auth.currentUser;

    if (freshUser == null) {
      throw Exception(
        'User session expired.',
      );
    }

    final emailVerified =
    _isEmailVerified(freshUser);

    final phoneVerified =
    _isPhoneVerified(freshUser);

    // ==========================================================
    // BOTH VERIFICATIONS REQUIRED
    // ==========================================================

    if (!emailVerified) {
      throw Exception(
        'Please verify your email first.',
      );
    }

    if (!phoneVerified) {
      throw Exception(
        'Please verify your phone number first.',
      );
    }

    // ==========================================================
    // SAVE SCREEN NAME
    // ==========================================================

    await _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(currentUid)
        .set({
      'screenName': cleanName,

      // Keep old field synchronized.
      AppConstants.fieldDisplayName:
      cleanName,

      'name': cleanName,

      'emailVerified':
      emailVerified,

      'phoneVerified':
      phoneVerified,

      'profileSetupCompleted':
      true,

      AppConstants.fieldUpdatedAt:
      FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also update Firebase Auth display name.
    await freshUser.updateDisplayName(
      cleanName,
    );
  }

  // ============================================================
  // WATCH CURRENT USER
  // ============================================================

  Stream<
      DocumentSnapshot<Map<String, dynamic>>>
  watchUser() {
    final currentUid = uid;

    if (currentUid == null) {
      return const Stream.empty();
    }

    return _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(currentUid)
        .snapshots();
  }

  // ============================================================
  // WATCH USER ROLE
  // ============================================================

  Stream<String> watchUserRole(
      String userUid,
      ) {
    return _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(userUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return AppConstants.roleUser;
      }

      final role =
      doc.data()?[
      AppConstants.fieldRole
      ];

      if (role is String) {
        final normalized =
        role.trim().toLowerCase();

        if (AppConstants.allRoles
            .contains(normalized)) {
          return normalized;
        }
      }

      return AppConstants.roleUser;
    });
  }

  // ============================================================
  // GET ALL USERS
  // ============================================================

  Stream<List<AppUser>> watchAllUsers() {
    return _db
        .collection(
      AppConstants.usersCollection,
    )
        .orderBy(
      AppConstants.fieldCreatedAt,
      descending: true,
    )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        DateTime? created;

        final createdValue =
        data[
        AppConstants.fieldCreatedAt
        ];

        if (createdValue is Timestamp) {
          created =
              createdValue.toDate();
        }

        return AppUser(
          uid: doc.id,

          email:
          data[
          AppConstants.fieldEmail
          ],

          displayName:
          getDisplayName(data),

          phone:
          data['phone'],

          role:
          data[
          AppConstants.fieldRole
          ] ??
              AppConstants.roleUser,

          createdAt:
          created,
        );
      }).toList();
    });
  }

  // ============================================================
  // UPDATE ROLE
  // ============================================================

  Future<void> updateUserRole(
      String userUid,
      String role,
      ) async {
    final normalized =
    role.trim().toLowerCase();

    if (!AppConstants.allRoles
        .contains(normalized)) {
      throw Exception(
        'Invalid user role.',
      );
    }

    await _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(userUid)
        .update({
      AppConstants.fieldRole:
      normalized,

      AppConstants.fieldUpdatedAt:
      FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DELETE USER
  // ============================================================

  Future<void> deleteUser(
      String userUid,
      ) async {
    try {
      await _db
          .collection(
        AppConstants.usersCollection,
      )
          .doc(userUid)
          .delete();

      try {
        final photoRef =
        _storage
            .ref()
            .child(
          AppConstants.storageUsers,
        )
            .child(userUid)
            .child(
          AppConstants
              .storageProfilePhoto,
        );

        await photoRef.delete();
      } catch (_) {
        // Profile photo may not exist.
      }
    } catch (e) {
      throw Exception(
        'User delete karne mein masla: $e',
      );
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile({
    required String name,
    required String email,
    required String phone,
  }) async {
    final currentUid = uid;

    if (currentUid == null) {
      return;
    }

    final cleanName =
    name.trim();

    await _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(currentUid)
        .set({
      AppConstants.fieldDisplayName:
      cleanName,

      'screenName':
      cleanName,

      'name':
      cleanName,

      AppConstants.fieldEmail:
      email.trim(),

      'phone':
      phone.trim(),

      AppConstants.fieldUpdatedAt:
      FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _auth.currentUser
        ?.updateDisplayName(
      cleanName,
    );
  }

  // ============================================================
  // UPDATE PHOTO
  // ============================================================

  Future<void> updatePhoto(
      File file,
      ) async {
    final currentUid = uid;

    if (currentUid == null) {
      return;
    }

    final ref = _storage
        .ref()
        .child(
      AppConstants.storageUsers,
    )
        .child(currentUid)
        .child(
      AppConstants.storageProfilePhoto,
    );

    await ref.putFile(file);

    final url =
    await ref.getDownloadURL();

    await _db
        .collection(
      AppConstants.usersCollection,
    )
        .doc(currentUid)
        .update({
      AppConstants.fieldPhotoUrl:
      url,

      AppConstants.fieldUpdatedAt:
      FieldValue.serverTimestamp(),
    });

    await _auth.currentUser
        ?.updatePhotoURL(url);
  }

  // ============================================================
  // INVITE
  // ============================================================

  Future<String?> createInvite(
      String email,
      String role,
      ) async {
    final cleanEmail =
    email.trim().toLowerCase();

    final normalizedRole =
    role.trim().toLowerCase();

    if (!AppConstants.allRoles
        .contains(normalizedRole)) {
      return null;
    }

    final existing = await _db
        .collection(
      AppConstants.invitationsCollection,
    )
        .where(
      AppConstants.fieldEmail,
      isEqualTo: cleanEmail,
    )
        .where(
      AppConstants.fieldStatus,
      isEqualTo:
      AppConstants.inviteStatusPending,
    )
        .get();

    if (existing.docs.isNotEmpty) {
      return null;
    }

    final doc = await _db
        .collection(
      AppConstants.invitationsCollection,
    )
        .add({
      AppConstants.fieldEmail:
      cleanEmail,

      AppConstants.fieldRole:
      normalizedRole,

      AppConstants.fieldStatus:
      AppConstants.inviteStatusPending,

      AppConstants.fieldCreatedAt:
      FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  static String getDisplayName(
      Map<String, dynamic>? data,
      ) {
    if (data == null) {
      return 'User';
    }

    final screenName =
    data['screenName'];

    if (screenName != null &&
        screenName.toString().trim().isNotEmpty) {
      return screenName.toString().trim();
    }

    final displayName =
    data[AppConstants.fieldDisplayName];

    if (displayName != null &&
        displayName.toString().trim().isNotEmpty) {
      return displayName.toString().trim();
    }

    final oldName =
    data['name'];

    if (oldName != null &&
        oldName.toString().trim().isNotEmpty) {
      return oldName.toString().trim();
    }

    final username =
    data['username'];

    if (username != null &&
        username.toString().trim().isNotEmpty) {
      return username.toString().trim();
    }

    return 'User';
  }
}