import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String userId;
  final bool isRead;
  final Timestamp time;
  final String type;
  final String? questionId;
  final String? route;
  final String? messageId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.userId,
    required this.isRead,
    required this.time,
    required this.type,
    this.questionId,
    this.route,
    this.messageId,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return NotificationModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      message: data['message']?.toString() ?? '',
      userId: data['userId']?.toString() ?? '',
      isRead: data['isRead'] == true,
      time: data['time'] as Timestamp? ?? Timestamp.now(),
      type: data['type']?.toString() ?? 'general',
      questionId: data['questionId']?.toString(),
      route: data['route']?.toString(),
      messageId: data['messageId']?.toString(),
    );
  }
}
