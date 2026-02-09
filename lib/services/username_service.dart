import 'package:cloud_firestore/cloud_firestore.dart';

class UsernameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔍 Get username of user
  Future<String?> getUsername(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['username'];
  }

  /// ✅ Check availability
  Future<bool> isUsernameAvailable(String username) async {
    final doc = await _db.collection('usernames').doc(username).get();
    return !doc.exists;
  }

  /// 🔐 Set username (transaction-safe)
  Future<void> setUsername({
    required String uid,
    required String username,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final usernameRef = _db.collection('usernames').doc(username);

    await _db.runTransaction((tx) async {
      final usernameSnap = await tx.get(usernameRef);

      if (usernameSnap.exists) {
        throw Exception('Username already taken');
      }

      // reserve username
      tx.set(usernameRef, {
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // set in user profile
      tx.update(userRef, {
        'username': username,
      });
    });
  }
}
