import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/question_model.dart';

class QuestionsFirestoreService {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  // =========================================================
  // 🔍 KEYWORD GENERATOR
  // =========================================================

  List<String> _generateKeywords(String text) {
    final words =
    text.toLowerCase().split(RegExp(r'\s+'));

    return words
        .where((word) => word.length > 2)
        .map(
          (word) => word.replaceAll(
        RegExp(r'\W'),
        '',
      ),
    )
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList();
  }

  // =========================================================
  // 👤 CURRENT USER
  // =========================================================

  User? get currentUser =>
      FirebaseAuth.instance.currentUser;

  // =========================================================
  // ➕ ASK QUESTION
  // =========================================================

  Future<void> addQuestion({
    required String questionText,
    required String userId,
    required String askedBy,
    bool hideAskedByName = false,
  }) async {
    final cleanQuestion =
    questionText.trim();

    if (cleanQuestion.isEmpty) {
      throw Exception(
        'Question cannot be empty',
      );
    }

    await _db.collection('questions').add({
      'questionText': cleanQuestion,

      'askedBy': askedBy,
      'uid': userId,

      'category': null,
      'subCategory': null,

      // New question pehle NEW rahega.
      'status': 'new',

      'answer': null,
      'reference': null,

      'keywords':
      _generateKeywords(cleanQuestion),

      // Published answer ke liye existing fields.
      'muftiId': null,
      'muftiName': null,

      // =====================================================
      // CLAIM SYSTEM
      // =====================================================

      'claimedByUid': null,
      'claimedByName': null,
      'claimedAt': null,
      'claimExpiresAt': null,

      'questionEditedByMufti': false,

      'hideAskedByName':
      hideAskedByName,

      'likeCount': 0,
      'shareCount': 0,

      'createdAt':
      FieldValue.serverTimestamp(),

      'updatedAt':
      FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // 📊 STREAM QUESTIONS
  // =========================================================

  Stream<List<QuestionModel>> watchQuestions({
    required String role,
  }) {
    Query<Map<String, dynamic>> query =
    _db.collection('questions');

    if (role == 'user') {
      query = query.where(
        'status',
        isEqualTo: 'published',
      );
    }

    query = query.orderBy(
      'updatedAt',
      descending: true,
    );

    return query.snapshots().map(
          (snapshot) {
        return snapshot.docs
            .map(
              (doc) =>
              QuestionModel.fromFirestore(doc),
        )
            .toList();
      },
    );
  }

  // =========================================================
  // 👤 MY QUESTIONS
  // =========================================================

  Stream<List<QuestionModel>> watchMyQuestions() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(
        <QuestionModel>[],
      );
    }

    return _db
        .collection('questions')
        .where(
      'uid',
      isEqualTo: user.uid,
    )
        .snapshots()
        .map(
          (snapshot) {
        final questions = snapshot.docs
            .map(
              (doc) =>
              QuestionModel.fromFirestore(doc),
        )
            .toList();

        questions.sort(
              (a, b) {
            final aTime =
                a.updatedAt ?? a.createdAt;

            final bTime =
                b.updatedAt ?? b.createdAt;

            return bTime.compareTo(aTime);
          },
        );

        return questions;
      },
    );
  }

  // =========================================================
  // 📖 PUBLISHED QUESTIONS
  // =========================================================

  Stream<List<QuestionModel>>
  streamPublishedQuestions() {
    return _db
        .collection('questions')
        .where(
      'status',
      isEqualTo: 'published',
    )
        .orderBy(
      'updatedAt',
      descending: true,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) =>
            QuestionModel.fromFirestore(doc),
      )
          .toList(),
    );
  }

  // =========================================================
  // ⏳ MARK AS PENDING
  // =========================================================
  //
  // NEW question ko koi Mufti OPEN karega:
  //
  // new → pending
  //
  // IMPORTANT:
  // OPEN karne se CLAIM nahi hoga.
  //
  // Kisi bhi Mufti ko baad mein CLAIM karne ka mauqa rahega.
  // =========================================================

  Future<void> markAsPending(
      String questionId,
      ) async {
    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    await _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Question not found',
          );
        }

        final data = snapshot.data();

        final status =
            data?['status']?.toString() ?? '';

        // Sirf NEW question ko pending kiya jayega.
        if (status == 'new') {
          transaction.update(
            questionRef,
            {
              'status': 'pending',

              // OPEN karne wale Mufti ko
              // automatically claim nahi kiya jayega.
              'muftiId': null,
              'muftiName': null,

              'claimedByUid': null,
              'claimedByName': null,
              'claimedAt': null,
              'claimExpiresAt': null,

              'updatedAt':
              FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );
  }

  // =========================================================
  // 🧹 CLAIM EXPIRY CHECK
  // =========================================================

  bool _isClaimExpired(
      dynamic claimExpiresAt,
      ) {
    if (claimExpiresAt is! Timestamp) {
      return false;
    }

    return claimExpiresAt
        .toDate()
        .isBefore(DateTime.now());
  }

  // =========================================================
  // 🔒 CLAIM QUESTION
  // =========================================================
  //
  // Koi bhi Mufti NEW/PENDING question ko CLAIM kar sakta hai.
  //
  // OPEN karne se claim nahi hota.
  //
  // CLAIM karne par:
  //
  // claimedByUid
  // claimedByName
  // claimedAt
  // claimExpiresAt (+3 days)
  //
  // save honge.
  //
  // Claim hone ke baad:
  //
  // Claim karne wale Mufti:
  //    Submit Answer
  //    Unclaim Question
  //
  // Baqi Muftis:
  //    Claimed
  //
  // Transaction ki wajah se do Mufti ek hi waqt mein
  // question claim nahi kar sakte.
  // =========================================================

  Future<void> claimQuestion(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    await _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Question not found',
          );
        }

        final data = snapshot.data();

        final status =
            data?['status']?.toString() ?? '';

        // Sirf NEW/PENDING question claim ho sakta hai.
        if (status != 'new' &&
            status != 'pending') {
          throw Exception(
            'This question is no longer available for claim',
          );
        }

        final existingClaimUid =
        data?['claimedByUid']?.toString();

        final existingExpiry =
        data?['claimExpiresAt'];

        // =====================================================
        // EXISTING CLAIM CHECK
        // =====================================================

        if (existingClaimUid != null &&
            existingClaimUid.isNotEmpty) {
          final expired =
          _isClaimExpired(
            existingExpiry,
          );

          // Active claim kisi aur Mufti ka hai.
          if (!expired &&
              existingClaimUid != user.uid) {
            throw Exception(
              'This question has already been claimed',
            );
          }

          // Same Mufti already claim kar chuka hai.
          if (!expired &&
              existingClaimUid == user.uid) {
            throw Exception(
              'You have already claimed this question',
            );
          }

          // Expired claim hone par naya claim allowed hai.
        }

        final now =
        Timestamp.now();

        final expiresAt =
        Timestamp.fromDate(
          DateTime.now().add(
            const Duration(days: 3),
          ),
        );

        final muftiName =
        user.displayName
            ?.trim()
            .isNotEmpty ==
            true
            ? user.displayName!.trim()
            : user.email
            ?.trim()
            .isNotEmpty ==
            true
            ? user.email!.trim()
            : user.uid;

        transaction.update(
          questionRef,
          {
            // NEW tha to CLAIM ke waqt PENDING ho jayega.
            'status': 'pending',

            // IMPORTANT:
            //
            // Claim ke waqt muftiId / muftiName
            // set NAHI honge.
            //
            // Ye actual answer submit hone par
            // set honge.
            'muftiId': null,
            'muftiName': null,

            // Actual CLAIM information.
            'claimedByUid': user.uid,
            'claimedByName': muftiName,
            'claimedAt': now,
            'claimExpiresAt': expiresAt,

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // =========================================================
  // 🔓 UNCLAIM QUESTION
  // =========================================================
  //
  // Sirf jis Mufti ne question CLAIM kiya hai
  // wahi UNCLAIM kar sakta hai.
  //
  // Question PENDING hi rahega.
  //
  // Unclaim ke baad sab Muftis ko dobara
  // CLAIM button mil sakta hai.
  // =========================================================

  Future<void> unclaimQuestion(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    await _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Question not found',
          );
        }

        final data = snapshot.data();

        final claimedByUid =
        data?['claimedByUid']?.toString();

        if (claimedByUid == null ||
            claimedByUid.isEmpty) {
          throw Exception(
            'Question is not claimed',
          );
        }

        if (claimedByUid != user.uid) {
          throw Exception(
            'Only the claiming Mufti can unclaim this question',
          );
        }

        transaction.update(
          questionRef,
          {
            // Question pending hi rahega.
            'status': 'pending',

            // Actual answer submit nahi hua.
            'muftiId': null,
            'muftiName': null,

            // Claim release.
            'claimedByUid': null,
            'claimedByName': null,
            'claimedAt': null,
            'claimExpiresAt': null,

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // =========================================================
  // ⏰ RELEASE EXPIRED CLAIM
  // =========================================================
  //
  // 3 days complete hone ke baad claim release karne ke liye.
  //
  // Firestore khud Timestamp expire hone par document update
  // nahi karta.
  //
  // Is method ko app/backend se call karna hoga.
  // =========================================================

  Future<bool> releaseExpiredClaim(
      String questionId,
      ) async {
    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    return _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          return false;
        }

        final data = snapshot.data();

        final claimedByUid =
        data?['claimedByUid']?.toString();

        final claimExpiresAt =
        data?['claimExpiresAt'];

        if (claimedByUid == null ||
            claimedByUid.isEmpty) {
          return false;
        }

        if (!_isClaimExpired(
          claimExpiresAt,
        )) {
          return false;
        }

        transaction.update(
          questionRef,
          {
            'status': 'pending',

            'muftiId': null,
            'muftiName': null,

            'claimedByUid': null,
            'claimedByName': null,
            'claimedAt': null,
            'claimExpiresAt': null,

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  // =========================================================
  // 🔎 GET SINGLE QUESTION
  // =========================================================

  Future<QuestionModel?> getQuestion(
      String questionId,
      ) async {
    final doc = await _db
        .collection('questions')
        .doc(questionId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return QuestionModel.fromFirestore(doc);
  }

  // =========================================================
  // ✏️ EDIT QUESTION BY ADMIN / OWNER
  // =========================================================
  //
  // AnswerQuestionScreen mein Admin/Owner ke liye
  // ye method use hota hai.
  //
  // Question edit karne par editHistory subcollection mein
  // complete record save hota hai.
  //
  // IMPORTANT:
  // Is method se claim information change nahi hoti.
  // =========================================================

  Future<void> editQuestionByAdminOrOwner({
    required String questionId,
    required String newQuestionText,
    required String editorRole,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    if (editorRole != 'admin' &&
        editorRole != 'owner') {
      throw Exception(
        'Only Admin or Owner can edit this question',
      );
    }

    final cleanQuestion =
    newQuestionText.trim();

    if (cleanQuestion.isEmpty) {
      throw Exception(
        'Question cannot be empty',
      );
    }

    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    await _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Question not found',
          );
        }

        final data = snapshot.data();

        final oldQuestion =
            data?['questionText']
                ?.toString() ??
                data?['question']
                    ?.toString() ??
                '';

        if (oldQuestion.trim() ==
            cleanQuestion) {
          return;
        }

        final userName =
        user.displayName
            ?.trim()
            .isNotEmpty ==
            true
            ? user.displayName!.trim()
            : user.email
            ?.trim()
            .isNotEmpty ==
            true
            ? user.email!.trim()
            : user.uid;

        // =====================================================
        // EDIT HISTORY
        // =====================================================

        final historyRef =
        questionRef
            .collection('editHistory')
            .doc();

        transaction.set(
          historyRef,
          {
            'oldQuestion':
            oldQuestion,

            'newQuestion':
            cleanQuestion,

            'editedBy':
            userName,

            'editorUid':
            user.uid,

            'editorRole':
            editorRole,

            'editedAt':
            FieldValue.serverTimestamp(),
          },
        );

        // =====================================================
        // QUESTION UPDATE
        // =====================================================

        transaction.update(
          questionRef,
          {
            'questionText':
            cleanQuestion,

            'keywords':
            _generateKeywords(
              cleanQuestion,
            ),

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // =========================================================
  // ✍️ MUFTI ANSWER + ONE-TIME QUESTION EDIT OPPORTUNITY
  // =========================================================

  Future<void> submitMuftiAnswer({
    required String questionId,
    required String questionText,
    required String answerText,
    required String category,
    required String subCategory,
    required String reference,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final cleanQuestion =
    questionText.trim();

    final cleanAnswer =
    answerText.trim();

    final muftiName =
    user.displayName
        ?.trim()
        .isNotEmpty ==
        true
        ? user.displayName!.trim()
        : user.email
        ?.trim()
        .isNotEmpty ==
        true
        ? user.email!.trim()
        : user.uid;

    if (cleanQuestion.isEmpty) {
      throw Exception(
        'Question cannot be empty',
      );
    }

    if (cleanAnswer.isEmpty) {
      throw Exception(
        'Answer cannot be empty',
      );
    }

    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    await _db.runTransaction(
          (transaction) async {
        final snapshot =
        await transaction.get(
          questionRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Question not found',
          );
        }

        final data = snapshot.data();

        // ===================================================
        // CLAIM CHECK
        // ===================================================

        final claimedByUid =
        data?['claimedByUid']?.toString();

        if (claimedByUid == null ||
            claimedByUid.isEmpty) {
          throw Exception(
            'Please claim this question before submitting the answer',
          );
        }

        if (claimedByUid != user.uid) {
          throw Exception(
            'This question is claimed by another Mufti',
          );
        }

        final claimExpiresAt =
        data?['claimExpiresAt'];

        if (_isClaimExpired(
          claimExpiresAt,
        )) {
          throw Exception(
            'Your 3-day claim has expired. Please claim the question again.',
          );
        }

        // ===================================================
        // ONE-TIME EDIT CHECK
        // ===================================================

        final alreadyUsed =
            data?['questionEditedByMufti'] ==
                true;

        if (alreadyUsed) {
          throw Exception(
            'Mufti edit opportunity already used',
          );
        }

        final oldQuestion =
            data?['questionText']
                ?.toString() ??
                data?['question']
                    ?.toString() ??
                '';

        final questionChanged =
            oldQuestion.trim() !=
                cleanQuestion;

        // ===================================================
        // EDIT HISTORY
        // ===================================================

        if (questionChanged) {
          final historyRef =
          questionRef
              .collection('editHistory')
              .doc();

          transaction.set(
            historyRef,
            {
              'oldQuestion':
              oldQuestion,

              'newQuestion':
              cleanQuestion,

              'editedBy':
              muftiName,

              'editorUid':
              user.uid,

              'editorRole':
              'mufti',

              'editedAt':
              FieldValue.serverTimestamp(),
            },
          );
        }

        // ===================================================
        // QUESTION + ANSWER UPDATE
        // ===================================================

        transaction.update(
          questionRef,
          {
            'questionText':
            cleanQuestion,

            'keywords':
            _generateKeywords(
              cleanQuestion,
            ),

            'answer':
            cleanAnswer,

            'category':
            category,

            'subCategory':
            subCategory,

            'reference':
            reference.trim(),

            'status':
            'published',

            // Actual answer dene wale Mufti.
            'muftiId':
            user.uid,

            'muftiName':
            muftiName,

            // Claim information retain rahegi.
            'claimedByUid':
            user.uid,

            'claimedByName':
            muftiName,

            'claimedAt':
            data?['claimedAt'],

            // Published hone ke baad expiry ki zarurat nahi.
            'claimExpiresAt':
            null,

            'questionEditedByMufti':
            true,

            'updatedAt':
            FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // =========================================================
  // ✅ OWNER / ADMIN FULL ANSWER SUBMIT
  // =========================================================

  Future<void> submitFullAnswer({
    required String questionId,
    required String answerText,
    required String category,
    required String subCategory,
    required String reference,
  }) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception(
        'User not logged in',
      );
    }

    final cleanAnswer =
    answerText.trim();

    final muftiName =
    user.displayName
        ?.trim()
        .isNotEmpty ==
        true
        ? user.displayName!.trim()
        : user.email
        ?.trim()
        .isNotEmpty ==
        true
        ? user.email!.trim()
        : user.uid;

    if (cleanAnswer.isEmpty) {
      throw Exception(
        'Answer cannot be empty',
      );
    }

    await _db
        .collection('questions')
        .doc(questionId)
        .update(
      {
        'answer':
        cleanAnswer,

        'category':
        category,

        'subCategory':
        subCategory,

        'reference':
        reference.trim(),

        'status':
        'published',

        'muftiId':
        user.uid,

        'muftiName':
        muftiName,

        'updatedAt':
        FieldValue.serverTimestamp(),
      },
    );
  }

  // =========================================================
  // ❤️ LIKE SYSTEM
  // =========================================================

  Future<bool> toggleLike(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final questionRef =
    _db.collection('questions').doc(
      questionId,
    );

    final likeRef =
    questionRef
        .collection('likes')
        .doc(user.uid);

    return _db.runTransaction(
          (transaction) async {
        final likeDoc =
        await transaction.get(
          likeRef,
        );

        if (likeDoc.exists) {
          transaction.delete(
            likeRef,
          );

          transaction.set(
            questionRef,
            {
              'likeCount':
              FieldValue.increment(-1),
            },
            SetOptions(
              merge: true,
            ),
          );

          return false;
        }

        transaction.set(
          likeRef,
          {
            'likedAt':
            FieldValue.serverTimestamp(),
          },
        );

        transaction.set(
          questionRef,
          {
            'likeCount':
            FieldValue.increment(1),
          },
          SetOptions(
            merge: true,
          ),
        );

        return true;
      },
    );
  }

  Future<bool> isLikedByUser(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final doc = await _db
        .collection('questions')
        .doc(questionId)
        .collection('likes')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  // =========================================================
  // 🔖 BOOKMARK SYSTEM
  // =========================================================

  Future<bool> toggleBookmarkRealtime(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final bookmarkRef =
    _db
        .collection('questions')
        .doc(questionId)
        .collection('bookmarks')
        .doc(user.uid);

    return _db.runTransaction(
          (transaction) async {
        final bookmarkDoc =
        await transaction.get(
          bookmarkRef,
        );

        if (bookmarkDoc.exists) {
          transaction.delete(
            bookmarkRef,
          );

          return false;
        }

        transaction.set(
          bookmarkRef,
          {
            'savedAt':
            FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  Future<bool> isBookmarkedByUser(
      String questionId,
      ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return false;
    }

    final doc = await _db
        .collection('questions')
        .doc(questionId)
        .collection('bookmarks')
        .doc(user.uid)
        .get();

    return doc.exists;
  }

  Stream<List<String>>
  getUserBookmarksRealtime() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(
        <String>[],
      );
    }

    return _db
        .collectionGroup('bookmarks')
        .where(
      FieldPath.documentId,
      isEqualTo: user.uid,
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => doc
            .reference
            .parent
            .parent
            ?.id,
      )
          .whereType<String>()
          .toList(),
    );
  }

  // =========================================================
  // 🔖 BOOKMARKED QUESTIONS
  // =========================================================

  Stream<List<QuestionModel>>
  getBookmarkedQuestions() {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value(
        <QuestionModel>[],
      );
    }

    return getUserBookmarksRealtime()
        .asyncMap(
          (ids) async {
        if (ids.isEmpty) {
          return <QuestionModel>[];
        }

        final docs = await Future.wait(
          ids.map(
                (id) => _db
                .collection('questions')
                .doc(id)
                .get(),
          ),
        );

        final questions = docs
            .where(
              (doc) => doc.exists,
        )
            .map(
              (doc) =>
              QuestionModel.fromFirestore(
                doc,
              ),
        )
            .toList();

        questions.sort(
              (a, b) {
            final aTime =
                a.updatedAt ?? a.createdAt;

            final bTime =
                b.updatedAt ?? b.createdAt;

            return bTime.compareTo(aTime);
          },
        );

        return questions;
      },
    );
  }

  // =========================================================
  // 📤 SHARE SYSTEM
  // =========================================================

  Future<void> incrementShareCount(
      String questionId,
      ) async {
    await _db
        .collection('questions')
        .doc(questionId)
        .set(
      {
        'shareCount':
        FieldValue.increment(1),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // =========================================================
  // 📊 REALTIME COUNTS
  // =========================================================

  Stream<int> getLikeCount(
      String questionId,
      ) {
    return _db
        .collection('questions')
        .doc(questionId)
        .collection('likes')
        .snapshots()
        .map(
          (snapshot) =>
      snapshot.docs.length,
    );
  }

  Stream<int> getShareCount(
      String questionId,
      ) {
    return _db
        .collection('questions')
        .doc(questionId)
        .snapshots()
        .map(
          (doc) =>
      (doc.data()?['shareCount']
      as num?)
          ?.toInt() ??
          0,
    );
  }

  // =========================================================
  // ❌ DELETE QUESTION
  // =========================================================

  Future<void> deleteQuestion(
      String questionId,
      ) async {
    await _db
        .collection('questions')
        .doc(questionId)
        .delete();
  }
}