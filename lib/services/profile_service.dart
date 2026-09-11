import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUid => _auth.currentUser?.uid;

  DocumentReference get _userDoc =>
      _firestore.collection('users').doc(currentUid);

  /// 🔹 Stream (UI expects)
  Stream<DocumentSnapshot> profileStream() {
    return _userDoc.snapshots();
  }

  /// 🔹 Update profile
  Future<void> updateProfile({
    required String name,
    String? email,
    String? phone,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (email != null) data['email'] = email;
    if (phone != null) data['phone'] = phone;

    await _userDoc.set(data, SetOptions(merge: true));
  }

  /// 🔹 REAL upload to Firebase Storage + save URL
  Future<void> uploadProfilePhoto(File file, String fileName) async {
    final uid = currentUid;
    if (uid == null) throw Exception('User not logged in');

    final ref = _storage.ref().child('profile_photos/$uid/$fileName');

    // upload
    final uploadTask = await ref.putFile(file);

    // get URL
    final downloadUrl = await uploadTask.ref.getDownloadURL();

    // save in Firestore
    await _userDoc.set({
      'photoUrl': downloadUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔹 Update phone
  Future<void> updatePhone(String phone) async {
    await _userDoc.set({
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔹 Device token
  Future<void> updateDeviceToken(String token) async {
    await _userDoc.set({
      'deviceToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// 🔹 Role stream
  Stream<String> roleStream() {
    return _userDoc.snapshots().map((doc) {
      return doc['role'] ?? 'user';
    });
  }
}