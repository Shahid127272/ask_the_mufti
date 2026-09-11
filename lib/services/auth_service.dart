import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _google = GoogleSignIn();
  static final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authState => _auth.authStateChanges();

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    try {
      await _google.signOut();
    } catch (_) {}

    try {
      await _auth.signOut();
    } catch (_) {}
  }

  // ============================================================
  // PROVIDER CHECKS
  // ============================================================

  bool isGoogleLinked() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
          (provider) => provider.providerId == 'google.com',
    );
  }

  bool isEmailPasswordLinked() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
          (provider) => provider.providerId == 'password',
    );
  }

  bool isEmailLinked() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // Google account already has an email identity.
    if (isGoogleLinked()) {
      return true;
    }

    return isEmailPasswordLinked();
  }

  bool isPhoneLinked() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    return user.providerData.any(
          (provider) => provider.providerId == 'phone',
    );
  }

  // ============================================================
  // EMAIL VERIFIED
  // ============================================================

  bool isEmailVerified() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // Google email is already verified.
    if (isGoogleLinked()) {
      return true;
    }

    return user.emailVerified;
  }

  // ============================================================
  // PHONE VERIFIED
  // ============================================================

  bool isPhoneVerified() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // Phone provider can only be linked after successful
    // Firebase phone verification.
    return isPhoneLinked() &&
        user.phoneNumber != null &&
        user.phoneNumber!.trim().isNotEmpty;
  }

  // ============================================================
  // EMAIL LOGIN
  // ============================================================

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user != null) {
        await _createUserDoc(
          user,
          user.displayName ?? '',
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _readableError(e);
    } catch (_) {
      return 'Login failed. Try again.';
    }
  }

  // ============================================================
  // FORGOT PASSWORD / PASSWORD RESET
  // ============================================================

  Future<String?> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      final cleanEmail = email.trim();

      if (cleanEmail.isEmpty) {
        return 'Please enter your email address.';
      }

      await _auth.sendPasswordResetEmail(
        email: cleanEmail,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _readableError(e);
    } catch (_) {
      return 'Could not send password reset email. Try again.';
    }
  }

  // ============================================================
  // EMAIL SIGNUP
  // ============================================================

  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // IMPORTANT:
      // Password ko trim nahi karna.
      // User ka exact password Firebase me save hoga.
      final credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;

      if (user == null) {
        return 'Account could not be created.';
      }

      // Temporary Firebase display name.
      // Actual Screen Name AccountSetupScreen se set hoga.
      if (displayName.trim().isNotEmpty) {
        await user.updateDisplayName(
          displayName.trim(),
        );
      }

      // Email verification.
      await user.sendEmailVerification();

      await user.reload();

      final freshUser = _auth.currentUser;

      if (freshUser != null) {
        await _createUserDoc(
          freshUser,
          displayName.trim(),
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _readableError(e);
    } catch (_) {
      return 'Signup failed. Try again.';
    }
  }

  // ============================================================
  // SEND EMAIL VERIFICATION
  // ============================================================

  Future<String?> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return 'No logged-in user found.';
      }

      await user.reload();

      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        return 'Session expired. Please login again.';
      }

      // Google accounts are already verified.
      if (isGoogleLinked() || freshUser.emailVerified) {
        return null;
      }

      if (freshUser.email == null ||
          freshUser.email!.trim().isEmpty) {
        return 'No email address is linked to this account.';
      }

      await freshUser.sendEmailVerification();

      return null;
    } on FirebaseAuthException catch (e) {
      return _readableError(e);
    } catch (_) {
      return 'Could not send verification email.';
    }
  }

  // ============================================================
  // REFRESH EMAIL VERIFICATION
  // ============================================================

  Future<bool> refreshEmailVerification() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return false;
      }

      await user.reload();

      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        return false;
      }

      if (freshUser.providerData.any(
            (provider) => provider.providerId == 'google.com',
      )) {
        return true;
      }

      return freshUser.emailVerified;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // LINK EMAIL + PASSWORD
  //
  // Used when a phone account has no email/password provider.
  // ============================================================

  Future<String?> linkEmailToCurrentUser({
    required String email,
    required String password,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        return 'Please login to your account first.';
      }

      final cleanEmail = email.trim();

      if (cleanEmail.isEmpty) {
        return 'Enter your email address.';
      }

      if (password.length < 6) {
        return 'Password must be at least 6 characters.';
      }

      await currentUser.reload();

      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        return 'Session expired. Please login again.';
      }

      // Email/password already linked.
      if (isEmailPasswordLinked()) {
        return null;
      }

      // Google already provides the email identity.
      if (isGoogleLinked()) {
        return null;
      }

      final credential =
      EmailAuthProvider.credential(
        email: cleanEmail,
        password: password,
      );

      final linkedCredential =
      await freshUser.linkWithCredential(
        credential,
      );

      final user = linkedCredential.user;

      if (user == null) {
        return 'Email could not be linked.';
      }

      await user.reload();

      final updatedUser = _auth.currentUser;

      if (updatedUser != null) {
        await _createUserDoc(
          updatedUser,
          updatedUser.displayName ?? 'User',
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LINK EMAIL ERROR: ${e.code}',
      );

      return _readableError(e);
    } catch (e) {
      debugPrint(
        'LINK EMAIL ERROR: $e',
      );

      return 'Email could not be linked.';
    }
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _google.signIn();

      if (googleUser == null) {
        return null;
      }

      final googleAuth =
      await googleUser.authentication;

      final credential =
      GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user != null) {
        await _createUserDoc(
          user,
          user.displayName ?? 'User',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'GOOGLE LOGIN ERROR: ${e.code}',
      );

      throw Exception(
        _readableError(e),
      );
    } catch (e) {
      debugPrint(
        'GOOGLE LOGIN ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // PHONE OTP
  //
  // linkToCurrentUser = false
  // --------------------------------
  // Normal phone login.
  //
  // linkToCurrentUser = true
  // --------------------------------
  // Existing account ke saath phone SAME UID par link.
  //
  // onVerified
  // --------------------------------
  // Android auto-verification successful hone par
  // AccountSetupScreen ko batane ke liye.
  // ============================================================

  Future<void> signInWithPhone({
    required String phone,
    required Function(String verificationId)
    codeSent,
    required Function(String error)
    onError,
    bool linkToCurrentUser = false,
    Function(User user)? onVerified,
  }) async {
    try {
      final phoneNumber = phone.trim();

      if (phoneNumber.isEmpty ||
          !phoneNumber.startsWith('+')) {
        onError(
          'Invalid phone number format.',
        );
        return;
      }

      if (linkToCurrentUser &&
          _auth.currentUser == null) {
        onError(
          'Please login to your account before linking your phone.',
        );
        return;
      }

      // If phone is already linked, no OTP is required.
      if (linkToCurrentUser &&
          isPhoneLinked()) {
        final existingUser = _auth.currentUser;

        if (existingUser != null) {
          await _createUserDoc(
            existingUser,
            existingUser.displayName ?? 'User',
          );

          onVerified?.call(existingUser);
        }

        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),

        // ======================================================
        // AUTO VERIFICATION
        // ======================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            if (linkToCurrentUser) {
              final currentUser =
                  _auth.currentUser;

              if (currentUser == null) {
                onError(
                  'Current account session not found.',
                );
                return;
              }

              await currentUser.reload();

              final freshUser =
                  _auth.currentUser;

              if (freshUser == null) {
                onError(
                  'Current account session not found.',
                );
                return;
              }

              // IMPORTANT:
              // Auto-verification may already have linked
              // the phone. Never link twice.
              final phoneAlreadyLinked =
              freshUser.providerData.any(
                    (provider) =>
                provider.providerId == 'phone',
              );

              if (!phoneAlreadyLinked) {
                await freshUser.linkWithCredential(
                  credential,
                );
              }

              await _auth.currentUser?.reload();

              final updatedUser =
                  _auth.currentUser;

              if (updatedUser != null) {
                await _createUserDoc(
                  updatedUser,
                  updatedUser.displayName ?? 'User',
                );

                onVerified?.call(updatedUser);
              }
            } else {
              // Normal phone login.
              final userCredential =
              await _auth.signInWithCredential(
                credential,
              );

              final user =
                  userCredential.user;

              if (user != null) {
                await _createUserDoc(
                  user,
                  user.displayName ?? 'User',
                );

                onVerified?.call(user);
              }
            }
          } on FirebaseAuthException catch (e) {
            onError(
              _readableError(e),
            );
          } catch (_) {
            onError(
              'Phone verification failed.',
            );
          }
        },

        // ======================================================
        // VERIFICATION FAILED
        // ======================================================

        verificationFailed:
            (FirebaseAuthException e) {
          onError(
            _readableError(e),
          );
        },

        // ======================================================
        // OTP SENT
        // ======================================================

        codeSent: (
            String verificationId,
            int? resendToken,
            ) {
          codeSent(
            verificationId,
          );
        },

        // ======================================================
        // TIMEOUT
        // ======================================================

        codeAutoRetrievalTimeout:
            (String verificationId) {},
      );
    } on FirebaseAuthException catch (e) {
      onError(
        _readableError(e),
      );
    } catch (_) {
      onError(
        'Failed to send OTP.',
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  //
  // linkToCurrentUser = true
  // --------------------------------
  // Current account ke andar phone link.
  // ============================================================

  Future<User?> verifyOtp({
    required String verificationId,
    required String otp,
    bool linkToCurrentUser = false,
  }) async {
    try {
      final code = otp.trim();

      if (code.length != 6) {
        return null;
      }

      final credential =
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      );

      // ========================================================
      // LINK PHONE TO CURRENT USER
      // ========================================================

      if (linkToCurrentUser) {
        final currentUser =
            _auth.currentUser;

        if (currentUser == null) {
          return null;
        }

        await currentUser.reload();

        final freshUser =
            _auth.currentUser;

        if (freshUser == null) {
          return null;
        }

        // Android auto-verification may already have linked it.
        final phoneAlreadyLinked =
        freshUser.providerData.any(
              (provider) =>
          provider.providerId == 'phone',
        );

        if (phoneAlreadyLinked) {
          await _createUserDoc(
            freshUser,
            freshUser.displayName ?? 'User',
          );

          return freshUser;
        }

        // Phone not linked yet → link it now.
        final linkedCredential =
        await freshUser.linkWithCredential(
          credential,
        );

        final user =
            linkedCredential.user;

        if (user == null) {
          return null;
        }

        await user.reload();

        final updatedUser =
            _auth.currentUser;

        if (updatedUser != null) {
          await _createUserDoc(
            updatedUser,
            updatedUser.displayName ?? 'User',
          );

          return updatedUser;
        }

        return user;
      }

      // ========================================================
      // NORMAL PHONE LOGIN
      // ========================================================

      final userCredential =
      await _auth.signInWithCredential(
        credential,
      );

      final user =
          userCredential.user;

      if (user != null) {
        await _createUserDoc(
          user,
          user.displayName ?? 'User',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'VERIFY OTP ERROR: ${e.code}',
      );

      return null;
    } catch (e) {
      debugPrint(
        'VERIFY OTP ERROR: $e',
      );

      return null;
    }
  }

  // ============================================================
  // DIRECT PHONE LINK
  // ============================================================

  Future<User?> linkPhoneCredential(
      PhoneAuthCredential credential,
      ) async {
    try {
      final currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        return null;
      }

      await currentUser.reload();

      final freshUser =
          _auth.currentUser;

      if (freshUser == null) {
        return null;
      }

      // Already linked → don't link again.
      if (isPhoneLinked()) {
        await _createUserDoc(
          freshUser,
          freshUser.displayName ?? 'User',
        );

        return freshUser;
      }

      final userCredential =
      await freshUser.linkWithCredential(
        credential,
      );

      final user =
          userCredential.user;

      if (user != null) {
        await user.reload();

        final updatedUser =
            _auth.currentUser;

        if (updatedUser != null) {
          await _createUserDoc(
            updatedUser,
            updatedUser.displayName ?? 'User',
          );

          return updatedUser;
        }

        return user;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LINK PHONE ERROR: ${e.code}',
      );

      rethrow;
    }
  }

  // ============================================================
  // RELOAD USER
  // ============================================================

  Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (_) {}
  }

  // ============================================================
  // CREATE / UPDATE USER DOCUMENT
  // ============================================================

  Future<void> _createUserDoc(
      User user,
      String defaultName,
      ) async {
    final ref =
    _db.collection('users').doc(user.uid);

    final doc = await ref.get();

    final data = doc.data();

    // Existing Screen Name preserve.
    final existingScreenName =
        data?['screenName']
            ?.toString()
            .trim() ??
            '';

    final firebaseName =
        user.displayName
            ?.trim() ??
            '';

    final fallbackName =
    defaultName.trim().isNotEmpty
        ? defaultName.trim()
        : firebaseName.isNotEmpty
        ? firebaseName
        : 'User';

    final emailVerified =
    isEmailVerifiedForUser(user);

    final phoneVerified =
        user.providerData.any(
              (provider) =>
          provider.providerId == 'phone',
        ) &&
            user.phoneNumber != null &&
            user.phoneNumber!
                .trim()
                .isNotEmpty;

    // ==========================================================
    // NEW USER
    // ==========================================================

    if (!doc.exists) {
      await ref.set({
        'uid': user.uid,

        'email': user.email,

        'phoneNumber': user.phoneNumber,

        'screenName': '',

        // Old field compatibility.
        'name': fallbackName,

        'role': 'user',

        'emailVerified': emailVerified,

        'phoneVerified': phoneVerified,

        'profileSetupCompleted': false,

        'createdAt':
        FieldValue.serverTimestamp(),

        'updatedAt':
        FieldValue.serverTimestamp(),
      });

      return;
    }

    // ==========================================================
    // EXISTING USER
    // ==========================================================

    final updateData =
    <String, dynamic>{
      'uid': user.uid,

      'email': user.email,

      'phoneNumber':
      user.phoneNumber,

      'emailVerified':
      emailVerified,

      'phoneVerified':
      phoneVerified,

      'updatedAt':
      FieldValue.serverTimestamp(),
    };

    // Screen Name missing ho to blank.
    if (existingScreenName.isEmpty) {
      updateData['screenName'] = '';
    }

    // Old name missing ho to fallback.
    final oldName =
    (data?['name']?.toString() ?? '')
        .trim();

    if (oldName.isEmpty) {
      updateData['name'] =
          fallbackName;
    }

    // Old users ke document me
    // setup field missing ho.
    if (data?['profileSetupCompleted'] ==
        null) {
      updateData[
      'profileSetupCompleted'] = false;
    }

    // Role existing ho to preserve.
    if (data?['role'] == null) {
      updateData['role'] = 'user';
    }

    await ref.set(
      updateData,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // EMAIL VERIFIED FOR SPECIFIC USER
  // ============================================================

  bool isEmailVerifiedForUser(User user) {
    final googleLinked =
    user.providerData.any(
          (provider) =>
      provider.providerId == 'google.com',
    );

    return user.emailVerified ||
        googleLinked;
  }

  // ============================================================
  // ERROR HANDLER
  // ============================================================

  String _readableError(
      FirebaseAuthException e,
      ) {
    switch (e.code) {
    // ========================================================
    // EMAIL
    // ========================================================

      case 'email-already-in-use':
        return 'This email is already registered. Please login.';

      case 'invalid-email':
        return 'Invalid email address.';

      case 'weak-password':
        return 'Password is too weak.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';

      case 'provider-already-linked':
        return 'This login method is already linked to your account.';

      case 'requires-recent-login':
        return 'Please login again and try this operation.';

      case 'operation-not-allowed':
        return 'This login method is currently disabled.';

    // ========================================================
    // PHONE
    // ========================================================

      case 'invalid-phone-number':
        return 'Invalid phone number format.';

      case 'invalid-verification-code':
        return 'Invalid OTP.';

      case 'invalid-verification-id':
        return 'OTP session is invalid. Request a new OTP.';

      case 'session-expired':
        return 'OTP expired. Request a new OTP.';

      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';

      case 'too-many-requests':
        return 'Too many attempts. Try again later.';

      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';

    // ========================================================
    // NETWORK
    // ========================================================

      case 'network-request-failed':
        return 'Check your internet connection.';

    // ========================================================
    // GOOGLE
    // ========================================================

      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using another login method.';

      case 'popup-closed-by-user':
        return 'Google login was cancelled.';

      default:
        return e.message ??
            'Authentication error.';
    }
  }
}