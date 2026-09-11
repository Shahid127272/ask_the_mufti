import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? phone;
  final String role;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.phone,
    required this.role,
    this.createdAt,
  });

  /// 🔹 From Firestore (existing - keep this)
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? created;
    final rawTime = data['createdAt'];
    if (rawTime is Timestamp) {
      created = rawTime.toDate();
    }

    return AppUser(
      uid: doc.id,
      email: data['email'] as String?,
      displayName:
      data['displayName'] as String? ??
          data['username'] as String?, // backward support
      phone: data['phone'] as String?,
      role: (data['role'] as String?) ?? 'user',
      createdAt: created,
    );
  }

  /// 🔥 ADD THIS (FIX for your error)
  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? created;
    final rawTime = map['createdAt'];

    if (rawTime is Timestamp) {
      created = rawTime.toDate();
    }

    return AppUser(
      uid: map['uid'] ?? '',
      email: map['email'],
      displayName: map['displayName'] ?? map['username'],
      phone: map['phone'],
      role: map['role'] ?? 'user',
      createdAt: created,
    );
  }
}