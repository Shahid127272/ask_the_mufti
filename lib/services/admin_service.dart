import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _users => _firestore.collection('users');

  /// Get all admins
  Stream<List<QueryDocumentSnapshot>> getAdmins() {
    return _users.where('role', isEqualTo: 'admin').snapshots().map(
          (snap) => snap.docs,
    );
  }

  /// Make user admin
  Future<void> makeAdmin(String uid) async {
    await _users.doc(uid).update({'role': 'admin'});
  }

  /// Remove admin
  Future<void> removeAdmin(String uid) async {
    await _users.doc(uid).update({'role': 'user'});
  }

  /// 🔥 FIX: MUST be inside class
  Future<void> updateUserRole(String uid, String role) async {
    await _users.doc(uid).update({'role': role});
  }
}