import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔹 Create user doc if not exists
  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email,
        'phone': user.phoneNumber,
        'role': 'user',
        'username': null, // 👈 baad me user set karega
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// 🔹 Fetch current username
  Future<String?> getCurrentUsername() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc =
      await _db.collection('users').doc(user.uid).get();

      if (!doc.exists) return null;

      final data = doc.data();
      final username = data?['username'];

      if (username is String && username.trim().isNotEmpty) {
        return username.trim();
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
