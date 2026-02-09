import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  User? get currentUser => _auth.currentUser;

  // ==============================
  // GOOGLE SIGN-IN (PRIMARY)
  // ==============================
  Future<User?> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;

    if (user != null) {
      await _userService.createUserIfNotExists(user);
    }

    return user;
  }

  // ==============================
  // PHONE LOGIN (SEND OTP)
  // ==============================
  Future<void> signInWithPhone({
    required String phone,
    required Function(String verificationId) codeSent,
    required Function(String error) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (cred) async {
        final result = await _auth.signInWithCredential(cred);
        if (result.user != null) {
          await _userService.createUserIfNotExists(result.user!);
        }
      },
      verificationFailed: (e) => onError(e.message ?? 'Phone verification failed'),
      codeSent: (id, _) => codeSent(id),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  // ==============================
  // VERIFY OTP
  // ==============================
  Future<User?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;

    if (user != null) {
      await _userService.createUserIfNotExists(user);
    }

    return user;
  }

  // ==============================
  // SIGN OUT
  // ==============================
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }
}
