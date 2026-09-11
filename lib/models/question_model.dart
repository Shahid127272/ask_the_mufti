import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String questionText;
  final String status;
  final String askedBy;

  final String? uid;

  final String? category;
  final String? subCategory;

  final String? answer;
  final String? reference;

  // =========================================================
  // PUBLISHED / ANSWERED BY MUFTI
  // =========================================================

  final String? muftiId;
  final String? muftiName;

  // =========================================================
  // CLAIM SYSTEM
  // =========================================================

  final String? claimedByUid;
  final String? claimedByName;

  final Timestamp? claimedAt;
  final Timestamp? claimExpiresAt;

  // =========================================================
  // OTHER
  // =========================================================

  final bool questionEditedByMufti;
  final bool hideAskedByName;

  final int likeCount;
  final int shareCount;

  final Timestamp createdAt;
  final Timestamp? updatedAt;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.status,
    required this.askedBy,
    required this.createdAt,

    this.uid,

    this.category,
    this.subCategory,

    this.answer,
    this.reference,

    this.muftiId,
    this.muftiName,

    // Claim
    this.claimedByUid,
    this.claimedByName,
    this.claimedAt,
    this.claimExpiresAt,

    this.questionEditedByMufti = false,
    this.hideAskedByName = false,

    this.likeCount = 0,
    this.shareCount = 0,

    this.updatedAt,
  });

  // =========================================================
  // FROM FIRESTORE
  // =========================================================

  factory QuestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    // =======================================================
    // EMPTY DOCUMENT
    // =======================================================

    if (data == null) {
      return QuestionModel(
        id: doc.id,
        questionText: '',
        status: 'pending',
        askedBy: 'User',
        createdAt: Timestamp.now(),
      );
    }

    // =======================================================
    // ASKED BY NAME
    // =======================================================

    String name =
        data['askedBy']?.toString() ?? 'User';

    if (name.length > 25) {
      name = 'User';
    }

    // =======================================================
    // ANSWER
    // =======================================================

    String? parsedAnswer;

    final answerData =
    data['answer'];

    if (answerData is Map) {
      parsedAnswer =
          answerData['text']?.toString();
    } else if (answerData != null) {
      parsedAnswer =
          answerData.toString();
    }

    // =======================================================
    // TIMESTAMPS
    // =======================================================

    final createdAtData =
    data['createdAt'];

    final updatedAtData =
    data['updatedAt'];

    final claimedAtData =
    data['claimedAt'];

    final claimExpiresAtData =
    data['claimExpiresAt'];

    // =======================================================
    // COUNTS
    // =======================================================

    final likeCountData =
    data['likeCount'];

    final shareCountData =
    data['shareCount'];

    // =======================================================
    // MODEL
    // =======================================================

    return QuestionModel(
      id: doc.id,

      questionText:
      data['questionText']?.toString() ??
          data['question']?.toString() ??
          '',

      status:
      data['status']?.toString() ??
          'pending',

      askedBy: name,

      uid:
      data['uid']?.toString(),

      category:
      data['category']?.toString(),

      subCategory:
      data['subCategory']?.toString(),

      answer:
      parsedAnswer,

      reference:
      data['reference']?.toString(),

      // =====================================================
      // PUBLISHED MUFTI
      // =====================================================

      muftiId:
      data['muftiId']?.toString(),

      muftiName:
      data['muftiName']?.toString(),

      // =====================================================
      // CLAIM
      // =====================================================

      claimedByUid:
      data['claimedByUid']?.toString(),

      claimedByName:
      data['claimedByName']?.toString(),

      claimedAt:
      claimedAtData is Timestamp
          ? claimedAtData
          : null,

      claimExpiresAt:
      claimExpiresAtData is Timestamp
          ? claimExpiresAtData
          : null,

      // =====================================================
      // OTHER
      // =====================================================

      questionEditedByMufti:
      data['questionEditedByMufti'] == true,

      hideAskedByName:
      data['hideAskedByName'] == true,

      likeCount:
      likeCountData is num
          ? likeCountData.toInt()
          : 0,

      shareCount:
      shareCountData is num
          ? shareCountData.toInt()
          : 0,

      createdAt:
      createdAtData is Timestamp
          ? createdAtData
          : Timestamp.now(),

      updatedAt:
      updatedAtData is Timestamp
          ? updatedAtData
          : null,
    );
  }

  // =========================================================
  // TO MAP
  // =========================================================

  Map<String, dynamic> toMap() {
    return {
      'questionText':
      questionText,

      'status':
      status,

      'askedBy':
      askedBy,

      'uid':
      uid,

      'category':
      category,

      'subCategory':
      subCategory,

      'answer':
      answer,

      'reference':
      reference,

      // =====================================================
      // PUBLISHED MUFTI
      // =====================================================

      'muftiId':
      muftiId,

      'muftiName':
      muftiName,

      // =====================================================
      // CLAIM
      // =====================================================

      'claimedByUid':
      claimedByUid,

      'claimedByName':
      claimedByName,

      'claimedAt':
      claimedAt,

      'claimExpiresAt':
      claimExpiresAt,

      // =====================================================
      // OTHER
      // =====================================================

      'questionEditedByMufti':
      questionEditedByMufti,

      'hideAskedByName':
      hideAskedByName,

      'likeCount':
      likeCount,

      'shareCount':
      shareCount,

      'createdAt':
      createdAt,

      'updatedAt':
      updatedAt,
    };
  }

  // =========================================================
  // 🔒 CLAIM STATUS
  // =========================================================

  bool get isClaimed {
    return claimedByUid != null &&
        claimedByUid!.isNotEmpty;
  }

  // =========================================================
  // ⏰ CLAIM EXPIRED
  // =========================================================

  bool get isClaimExpired {
    if (claimExpiresAt == null) {
      return false;
    }

    return claimExpiresAt!
        .toDate()
        .isBefore(DateTime.now());
  }

  // =========================================================
  // 👤 CLAIMED BY CURRENT USER
  // =========================================================

  bool isClaimedBy(String? userId) {
    if (userId == null ||
        userId.isEmpty) {
      return false;
    }

    return claimedByUid == userId;
  }

  // =========================================================
  // ⏳ CLAIM ACTIVE
  // =========================================================

  bool get hasActiveClaim {
    return isClaimed &&
        !isClaimExpired;
  }
}