import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fonts = context.watch<FontProvider>();
    final service = QuestionsFirestoreService();

    return AppScaffold(
      notificationCount: 0,
      body: StreamBuilder<List<QuestionModel>>(
        stream: service.getBookmarkedQuestions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Something went wrong\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final questions = snapshot.data ?? [];

          if (questions.isEmpty) {
            return Center(
              child: Text(
                'No bookmarks yet',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final q = questions[index];

              return ListTile(
                title: Text(
                  q.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily:
                    fonts.resolveFontFamily(
                      fonts.questionFont,
                    ),
                    fontSize: fonts.fontSize,
                    fontWeight: fonts.fontWeight,
                    fontStyle: fonts.isItalic
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
                subtitle: Text(
                  q.status.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.bookmark,
                        color: colorScheme.primary,
                      ),
                      tooltip: 'Remove Bookmark',
                      onPressed: () async {
                        try {
                          await service
                              .toggleBookmarkRealtime(
                            q.id,
                          );
                        } catch (e) {
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Bookmark update nahi ho saka.\n$e',
                              ),
                            ),
                          );
                        }
                      },
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AnswerDetailScreen(
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