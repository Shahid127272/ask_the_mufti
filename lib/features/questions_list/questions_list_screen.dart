import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';
import '../../services/questions_firestore_service.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../answer_detail/answer_detail_screen.dart';

class QuestionsListScreen extends StatelessWidget {
  QuestionsListScreen({super.key});

  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final role =
        context.watch<RoleViewController>().activeRole;
    final fonts = context.watch<FontProvider>();

    return AppScaffold(
      notificationCount: 0,
      body: StreamBuilder<List<QuestionModel>>(
        stream: _service.watchQuestions(
          role: role,
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

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No questions yet',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final questions = snapshot.data!;

          return ListView.builder(
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];

              Color statusColor;

              switch (q.status) {
                case 'published':
                  statusColor = colorScheme.primary;
                  break;

                case 'answered':
                  statusColor =
                      colorScheme.secondary;
                  break;

                default:
                  statusColor =
                      colorScheme.tertiary;
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
                  q.status,
                  style:
                  theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
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