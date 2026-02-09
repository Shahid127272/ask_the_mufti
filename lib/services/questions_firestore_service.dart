import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/question_model.dart';

class QuestionsFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────
  // ➕ USER → Add new question
  // ─────────────────────────────────────────────
  Future<void> addQuestion({
    required String questionText,
    required String userId,
    String? category,
    String? subCategory,
  }) async {
    await _db.collection('questions').add({
      'questionText': questionText,
      'askedBy': userId,
      'category': category,
      'subCategory': subCategory,
      'status': 'pending', // pending | answered | published
      'answer': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────────
  // 🔥 MUFTI / ADMIN → Pending questions
  // ─────────────────────────────────────────────
  Stream<List<QuestionModel>> streamPendingQuestions() {
    return _db
        .collection('questions')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  // 📢 USER FEEDS → ONLY PUBLISHED (ORDER BY PUBLISH TIME)
  // ─────────────────────────────────────────────
  Stream<List<QuestionModel>> streamPublishedQuestions({
    String? category,
    String? subCategory,
  }) {
    Query<Map<String, dynamic>> query = _db
        .collection('questions')
        .where('status', isEqualTo: 'published')
        .orderBy('updatedAt', descending: true); // 🔥 MOST IMPORTANT

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (subCategory != null && subCategory.isNotEmpty) {
      query = query.where('subCategory', isEqualTo: subCategory);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => QuestionModel.fromFirestore(doc))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  // ✍️ MUFTI → Answer submit (ANSWERED / PUBLISHED)
  // ─────────────────────────────────────────────
  Future<void> submitAnswer({
    required String questionId,
    required String answerText,
    required bool publish,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await _db.collection('questions').doc(questionId).update({
      'answer': {
        'text': answerText,
        'answeredBy': uid,
        'answeredAt': FieldValue.serverTimestamp(),
      },
      'status': publish ? 'published' : 'answered',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
