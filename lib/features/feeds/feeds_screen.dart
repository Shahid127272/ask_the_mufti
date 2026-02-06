import 'package:flutter/material.dart';
import '../../services/questions_firestore_service.dart';
import '../../models/question_model.dart';
import '../answer_detail/answer_detail_screen.dart';

class FeedsScreen extends StatelessWidget {
  final String? category;
  final String? subCategory;

  const FeedsScreen({
    super.key,
    this.category,
    this.subCategory,
  });

  @override
  Widget build(BuildContext context) {
    final service = QuestionsFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feeds'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<QuestionModel>>(
        // ✅ FIX HERE (named parameters)
        stream: service.streamPublishedQuestions(
          category: category,
          subCategory: subCategory,
        ),
        builder: (context, snapshot) {
          // 🔄 Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ Error
          if (snapshot.hasError) {
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
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: q.answer != null
                    ? const Text(
                  'Tap to read answer',
                  style: TextStyle(fontSize: 12),
                )
                    : null,
                trailing: const Text(
                  'See more',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
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
              );
            },
          );
        },
      ),
    );
  }
}
