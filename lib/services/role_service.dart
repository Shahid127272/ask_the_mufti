import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// owner | mufti | user
  Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;

    if (user == null) {
      return 'user'; // safety fallback
    }

    final uid = user.uid;
    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();

    // 🔹 First time user → create document
    if (!doc.exists) {
      await docRef.set({
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });
      return 'user';
    }

    // 🔹 Existing user
    final data = doc.data();
    return data?['role'] ?? 'user';
  }
}
