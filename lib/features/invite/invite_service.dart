import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class InviteService {

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ------------------------------------------------
  /// CREATE INVITE
  /// ------------------------------------------------

  Future<String?> createInvite(String email) async {

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return null;

    final userDoc = await _db.collection('users').doc(uid).get();

    final role = userDoc.data()?['role'];

    /// only owner/admin allowed
    if (role != 'owner' && role != 'admin') {
      throw Exception("Permission denied");
    }

    email = email.toLowerCase();

    /// duplicate invite prevention
    final existing = await _db
        .collection('invitations')
        .where('email', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) {
      return null;
    }

    final inviteId = const Uuid().v4();

    await _db.collection('invitations').doc(inviteId).set({

      "inviteId": inviteId,

      "email": email,
      "role": "mufti",

      "status": "pending",

      "createdBy": uid,

      "createdAt": FieldValue.serverTimestamp(),

      /// 72 hours validity
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(
          const Duration(hours: 72),
        ),
      ),

    });

    return inviteId;
  }

  /// ------------------------------------------------
  /// ACCEPT INVITE
  /// ------------------------------------------------

  Future<void> acceptInvite({
    required String inviteId,
    required String uid,
    required String email,
  }) async {

    email = email.toLowerCase();

    final inviteRef =
    _db.collection('invitations').doc(inviteId);

    await _db.runTransaction((tx) async {

      final doc = await tx.get(inviteRef);

      if (!doc.exists) return;

      final data = doc.data()!;

      /// already used
      if (data["status"] != "pending") return;

      /// email mismatch
      if (data["email"] != email) return;

      /// expiry check
      final expiresAt = data["expiresAt"] as Timestamp?;

      if (expiresAt != null &&
          expiresAt.toDate().isBefore(DateTime.now())) {

        tx.update(inviteRef, {
          "status": "expired",
        });

        return;
      }

      /// role overwrite protection
      final userRef = _db.collection('users').doc(uid);

      final userDoc = await tx.get(userRef);

      final currentRole = userDoc.data()?['role'];

      if (currentRole == "owner" || currentRole == "admin") {
        return;
      }

      /// assign mufti role
      tx.update(userRef, {
        "role": "mufti"
      });

      /// mark invite accepted
      tx.update(inviteRef, {

        "status": "accepted",

        "acceptedAt": FieldValue.serverTimestamp(),

        "acceptedBy": uid,

      });

    });

  }

  /// ------------------------------------------------
  /// WATCH INVITES (ADMIN PANEL)
  /// ------------------------------------------------

  Stream<QuerySnapshot<Map<String, dynamic>>> watchInvites() {

    return _db
        .collection('invitations')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

}