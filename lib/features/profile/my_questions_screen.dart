import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final service = QuestionsFirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Questions"),
      ),

      body: StreamBuilder<List<QuestionModel>>(

        // 🔥 FIX: direct firestore query (method removed tha)
        stream: service.watchQuestions(
          role: 'user',
        ),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          // 🔥 FILTER: sirf current user ke questions
          final questions = (snapshot.data ?? [])
              .where((q) => q.uid == uid)
              .toList();

          if (questions.isEmpty) {
            return const Center(
              child: Text("You haven't asked any questions yet"),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),

            itemCount: questions.length,

            separatorBuilder: (_, __) => const Divider(),

            itemBuilder: (context, index) {

              final q = questions[index];

              Color statusColor;

              switch (q.status) {
                case 'published':
                  statusColor = Colors.green;
                  break;

                case 'pending':
                  statusColor = Colors.orange;
                  break;

                default:
                  statusColor = Colors.grey;
              }

              return ListTile(

                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                subtitle: Text(
                  q.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                  ),
                ),

                trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AnswerDetailScreen(question: q),
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