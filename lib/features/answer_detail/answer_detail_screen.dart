import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/question_model.dart';

class AnswerDetailScreen extends StatelessWidget {
  final QuestionModel question;

  const AnswerDetailScreen({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final answer = question.answer as Map<String, dynamic>?;

    final answerText = answer?['text'] ?? '';
    final answeredAt = answer?['answeredAt'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Answer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: answer == null
            ? const Center(child: Text('Answer not available'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ❓ Question
            Text(
              question.questionText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),

            const Divider(height: 32),

            /// ✅ Answer
            Text(
              answerText,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 24),

            /// 🕒 Date
            if (answeredAt != null)
              Text(
                'Answered on: ${DateFormat.yMMMd().format(answeredAt.toDate())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
