import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class MyQuestionsScreen extends StatelessWidget {
  const MyQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fonts = context.watch<FontProvider>();

    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return AppScaffold(
        notificationCount: 0,
        body: Center(
          child: Text(
            "User not logged in",
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    final service = QuestionsFirestoreService();

    return AppScaffold(
      notificationCount: 0,
      body: StreamBuilder<List<QuestionModel>>(
        stream: service.watchQuestions(
          role: 'user',
        ),
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
              child: Text(
                "Something went wrong",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final questions = (snapshot.data ?? [])
              .where((q) => q.uid == uid)
              .toList();

          if (questions.isEmpty) {
            return Center(
              child: Text(
                "You haven't asked any questions yet",
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: questions.length,
            separatorBuilder: (_, __) => Divider(
              color: colorScheme.outlineVariant,
            ),
            itemBuilder: (context, index) {
              final q = questions[index];

              Color statusColor;

              switch (q.status) {
                case 'published':
                  statusColor = colorScheme.primary;
                  break;

                case 'pending':
                  statusColor = colorScheme.tertiary;
                  break;

                default:
                  statusColor =
                      colorScheme.onSurfaceVariant;
              }

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
                  style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color:
                  colorScheme.onSurfaceVariant,
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