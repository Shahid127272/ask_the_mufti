import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Roles: admin | mufti | user
  Future<String> getCurrentUserRole() async {
    try {
      final user = _auth.currentUser;

      // 🔹 Guest / not logged in
      if (user == null) {
        return 'user';
      }

      final uid = user.uid;
      final docRef = _db.collection('users').doc(uid);

      // 🔹 Use server source fallback-safe
      final doc = await docRef.get(
        const GetOptions(source: Source.serverAndCache),
      );

      // 🔹 First-time user
      if (!doc.exists) {
        await docRef.set({
          'uid': uid,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return 'user';
      }

      final data = doc.data();
      final role = data?['role'];

      // 🔹 Role validation
      if (role is! String || role.trim().isEmpty) {
        return 'user';
      }

      return role.trim();
    } catch (_) {
      // 🔥 Never crash app (release safety)
      return 'user';
    }
  }
}
