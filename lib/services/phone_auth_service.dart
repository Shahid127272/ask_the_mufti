import 'package:firebase_auth/firebase_auth.dart';

class PhoneAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _verificationId;
  bool _autoVerified = false;

  /// ============================================================
  /// SEND PHONE OTP
  /// ============================================================

  Future<void> sendOTP({
    required String phone,
    required Function(String verificationId) codeSent,
  }) async {
    _verificationId = null;
    _autoVerified = false;

    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    if (user.phoneNumber != null &&
        user.phoneNumber!.isNotEmpty) {
      throw Exception('A phone number is already linked to this account.');
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phone.trim(),

      timeout: const Duration(seconds: 60),

      /// Android automatic verification
      verificationCompleted:
          (PhoneAuthCredential credential) async {
        try {
          final currentUser = _auth.currentUser;

          if (currentUser == null) {
            return;
          }

          await currentUser.linkWithCredential(credential);

          _autoVerified = true;
        } on FirebaseAuthException catch (e) {
          // Do not crash the verification flow.
          // If user enters OTP manually, verifyOTP() will handle it.
          if (e.code != 'credential-already-in-use' &&
              e.code != 'provider-already-linked') {
            throw Exception(_readableError(e));
          }
        }
      },

      /// Firebase rejected phone number / SMS request
      verificationFailed:
          (FirebaseAuthException e) {
        throw Exception(_readableError(e));
      },

      /// OTP sent
      codeSent:
          (String verificationId, int? resendToken) {
        _verificationId = verificationId;

        codeSent(verificationId);
      },

      /// Automatic retrieval timed out
      codeAutoRetrievalTimeout:
          (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// ============================================================
  /// VERIFY OTP AND LINK PHONE
  /// ============================================================

  Future<void> verifyOTP(String smsCode) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user found.');
    }

    if (_autoVerified) {
      return;
    }

    if (_verificationId == null ||
        _verificationId!.isEmpty) {
      throw Exception('OTP session expired. Please request OTP again.');
    }

    if (smsCode.trim().length != 6) {
      throw Exception('Please enter a valid 6-digit OTP.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode.trim(),
      );

      await user.linkWithCredential(credential);

      _autoVerified = true;
    } on FirebaseAuthException catch (e) {
      throw Exception(_readableError(e));
    }
  }

  /// ============================================================
  /// CHECK PHONE VERIFIED / LINKED
  /// ============================================================

  bool isPhoneLinked() {
    final user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final phone = user.phoneNumber;

    return phone != null && phone.isNotEmpty;
  }

  /// ============================================================
  /// ERROR HANDLER
  /// ============================================================

  String _readableError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check the code and try again.';

      case 'session-expired':
        return 'OTP expired. Please request a new OTP.';

      case 'invalid-phone-number':
        return 'Invalid phone number.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';

      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';

      case 'provider-already-linked':
        return 'A phone number is already linked to this account.';

      case 'requires-recent-login':
        return 'Please login again and then verify your phone number.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ?? 'Phone verification failed.';
    }
  }
}