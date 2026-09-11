import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/role_view_controller.dart';
import '../../services/questions_firestore_service.dart';
import '../../models/question_model.dart';
import '../answer_detail/answer_detail_screen.dart';

class QuestionsListScreen extends StatelessWidget {
  QuestionsListScreen({super.key});

  final QuestionsFirestoreService _service = QuestionsFirestoreService();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleViewController>().activeRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Questions'),
      ),
      body: StreamBuilder<List<QuestionModel>>(
        stream: _service.watchQuestions(role: role),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No questions yet'),
            );
          }

          final questions = snapshot.data!;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];

              return ListTile(
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  q.status,
                  style: TextStyle(
                    color: q.status == 'published'
                        ? Colors.green
                        : q.status == 'answered'
                            ? Colors.blue
                            : Colors.orange,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
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
