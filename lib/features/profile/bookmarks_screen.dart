import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = QuestionsFirestoreService();

    return AppScaffold(
      notificationCount: 0,
      body: StreamBuilder<List<QuestionModel>>(
        // ✅ DIRECT STREAM (FINAL FIX)
        stream: service.getBookmarkedQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return const Center(child: Text('No bookmarks yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor,
            ),
            itemBuilder: (context, index) {
              final q = questions[index];

              return ListTile(
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  q.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.bookmark,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () async {
                        await service.toggleBookmarkRealtime(q.id);
                      },
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnswerDetailScreen(question: q),
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