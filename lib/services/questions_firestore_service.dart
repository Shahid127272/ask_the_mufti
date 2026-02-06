import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/question_model.dart';

class QuestionsFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Add new question
  Future<void> addQuestion({
    required String questionText,
    required String userId,
    String? category,
    String? subCategory,
  }) async {
    await _db.collection('questions').add({
      'questionText': questionText,
      'status': 'pending',
      'askedBy': userId,
      'category': category,
      'subCategory': subCategory,
      'answer': null,
      'createdAt': Timestamp.now(),
    });
  }

  /// 🔥 Pending questions (Mufti)
  Stream<List<QuestionModel>> streamPendingQuestions() {
    return _db
        .collection('questions')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => QuestionModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        ),
      )
          .toList(),
    );
  }

  /// 📢 Published questions (Feeds)
  Stream<List<QuestionModel>> streamPublishedQuestions({
    String? category,
    String? subCategory,
  }) {
    Query query = _db
        .collection('questions')
        .where('status', isEqualTo: 'published');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (subCategory != null) {
      query = query.where('subCategory', isEqualTo: subCategory);
    }

    return query
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(
            (doc) => QuestionModel.fromFirestore(
          doc as DocumentSnapshot<Map<String, dynamic>>,
        ),
      )
          .toList(),
    );
  }

  /// ✍️ Update answer
  Future<void> updateAnswer({
    required String questionId,
    required String answer,
    required bool publish,
  }) async {
    await _db.collection('questions').doc(questionId).update({
      'answer': answer,
      'status': publish ? 'published' : 'answered',
    });
  }
}
