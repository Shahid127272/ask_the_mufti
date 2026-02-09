import 'package:flutter/material.dart';

import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class FeedsScreen extends StatelessWidget {
  final String? category;
  final String? subCategory;

  FeedsScreen({
    super.key,
    this.category,
    this.subCategory,
  });

  final QuestionsFirestoreService service =
  QuestionsFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeds'),
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: service.streamPublishedQuestions(
          category: category,
          subCategory: subCategory,
        ),
        builder: (context, snapshot) {
          // ⏳ Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ Error
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          // 📭 Empty
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No published questions yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final questions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final q = questions[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),

                // ❓ Question
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // 🏷 Status
                subtitle: const Text(
                  'Answered',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                  ),
                ),

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                ),

                // 🔗 CONNECT → DETAIL
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
              );
            },
          );
        },
      ),
    );
  }
}
