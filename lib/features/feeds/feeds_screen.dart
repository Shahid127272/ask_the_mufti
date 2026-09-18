import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class FeedsScreen extends StatefulWidget {
  final String? category;
  final String? subCategory;

  const FeedsScreen({
    super.key,
    this.category,
    this.subCategory,
  });

  @override
  State<FeedsScreen> createState() => _FeedsScreenState();
}

class _FeedsScreenState extends State<FeedsScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  Future<void> _refresh() async {
    setState(() {});
    await Future.delayed(
      const Duration(milliseconds: 500),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    context.watch<RoleViewController>().activeRole;

    return AppScaffold(
      notificationCount: 0,
      body: Column(
        children: [
          /// CATEGORY
          if (widget.category != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  label: Text(widget.category!),
                ),
              ),
            ),

          /// FEED
          Expanded(
            child: StreamBuilder<List<QuestionModel>>(
              stream: _service.streamPublishedQuestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Something went wrong",
                      style: theme.textTheme.titleMedium,
                    ),
                  );
                }

                List<QuestionModel> questions =
                    snapshot.data ?? [];

                /// CATEGORY FILTER
                if (widget.category != null &&
                    widget.category!.isNotEmpty) {
                  questions = questions
                      .where(
                        (q) => q.category == widget.category,
                  )
                      .toList();
                }

                /// SUB CATEGORY FILTER
                if (widget.subCategory != null &&
                    widget.subCategory!.isNotEmpty) {
                  questions = questions
                      .where(
                        (q) =>
                    q.subCategory == widget.subCategory,
                  )
                      .toList();
                }

                /// EMPTY STATE
                if (questions.isEmpty) {
                  return Center(
                    child: Text(
                      "No Answers Found",
                      style: theme.textTheme.titleMedium,
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.builder(
                    physics:
                    const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 4,
                      bottom: 20,
                    ),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];

                      return _QuestionCard(
                        question: question,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final QuestionModel question;

  const _QuestionCard({
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fonts = context.watch<FontProvider>();

    final questionFontFamily =
    fonts.resolveFontFamily(
      fonts.questionFont,
    );

    final category =
        question.category?.trim() ?? '';

    final subCategory =
        question.subCategory?.trim() ?? '';

    String categoryText = '';

    if (category.isNotEmpty &&
        subCategory.isNotEmpty) {
      categoryText = '$category • $subCategory';
    } else if (category.isNotEmpty) {
      categoryText = category;
    } else if (subCategory.isNotEmpty) {
      categoryText = subCategory;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnswerDetailScreen(
              question: question,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =====================================================
            // QUESTION
            // =====================================================

            Text(
              question.questionText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: questionFontFamily,
                fontSize: fonts.fontSize,
                fontWeight: fonts.fontWeight,
                fontStyle: fonts.isItalic
                    ? FontStyle.italic
                    : FontStyle.normal,
                height: 1.4,
              ),
            ),

            // =====================================================
            // CATEGORY
            // =====================================================

            if (categoryText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                categoryText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 14),

            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}