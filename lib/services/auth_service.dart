import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  /// Anonymous login
  Future<User?> signInAnonymously() async {
    final cred = await _auth.signInAnonymously();
    return cred.user;
  }

  User? get currentUser => _auth.currentUser;
}
