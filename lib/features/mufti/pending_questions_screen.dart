import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import 'answer_question_screen.dart';

class PendingQuestionsScreen extends StatelessWidget {
  const PendingQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = QuestionsFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Questions'),
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: service.streamPendingQuestions(),
        builder: (context, snapshot) {
          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ❌ Error
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            return const Center(
              child: Text('Unable to load questions'),
            );
          }

          // 📭 Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No pending questions',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final questions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final q = questions[index];

              return ListTile(
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  q.category ?? 'Uncategorized',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                // ✅ Pending → Answer screen (REAL FLOW)
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnswerQuestionScreen(
                        question: q,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
