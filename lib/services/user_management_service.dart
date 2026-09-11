import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  /// 🔥 FIXED: now returns AppUser list (NOT raw docs)
  Stream<List<AppUser>> watchAllUsers() {
    return _users.snapshots().map(
          (snap) => snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser.fromMap(data);
      }).toList(),
    );
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    await _users.doc(uid).delete();
  }

  /// Update role
  Future<void> updateUserRole(String uid, String role) async {
    await _users.doc(uid).update({'role': role});
  }
}