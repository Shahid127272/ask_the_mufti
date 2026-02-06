import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String id;
  final String questionText;
  final String status; // pending | answered | published
  final String askedBy;
  final String? category;
  final String? subCategory;
  final String? answer;
  final Timestamp createdAt;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.status,
    required this.askedBy,
    required this.createdAt,
    this.category,
    this.subCategory,
    this.answer,
  });

  factory QuestionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data()!;
    return QuestionModel(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      status: data['status'] ?? 'pending',
      askedBy: data['askedBy'] ?? '',
      category: data['category'],
      subCategory: data['subCategory'],
      answer: data['answer'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'status': status,
      'askedBy': askedBy,
      'category': category,
      'subCategory': subCategory,
      'answer': answer,
      'createdAt': createdAt,
    };
  }
}
