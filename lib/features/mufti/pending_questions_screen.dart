import 'package:flutter/material.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class PendingQuestionsScreen extends StatelessWidget {
  PendingQuestionsScreen({super.key});

  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Questions'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<QuestionModel>>(
          stream: _service.streamPendingQuestions(),
          builder: (context, snapshot) {
            // 🔴 Error handling
            if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong'),
              );
            }

            // ⏳ Loading
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 📭 Empty state
            if (!snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No pending questions'),
              );
            }

            final questions = snapshot.data!;

            return ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(
                      q.questionText, // ✅ FIXED
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${q.category ?? 'Other'}'
                          '${q.subCategory != null ? ' • ${q.subCategory}' : ''}',
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AnswerDetailScreen(
                            question: q,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
