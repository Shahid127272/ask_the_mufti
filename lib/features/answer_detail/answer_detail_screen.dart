import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../../providers/font_provider.dart';

class AnswerDetailScreen extends StatefulWidget {
  final QuestionModel question;

  const AnswerDetailScreen({
    super.key,
    required this.question,
  });

  @override
  State<AnswerDetailScreen> createState() =>
      _AnswerDetailScreenState();
}

class _AnswerDetailScreenState
    extends State<AnswerDetailScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  bool _isBookmarked = false;
  bool _bookmarkLoading = true;

  QuestionModel get question => widget.question;

  // =========================================================
  // 🔖 BOOKMARK STATE
  // =========================================================

  @override
  void initState() {
    super.initState();
    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final bookmarked =
      await _service.isBookmarkedByUser(
        question.id,
      );

      if (!mounted) return;

      setState(() {
        _isBookmarked = bookmarked;
        _bookmarkLoading = false;
      });
    } catch (e) {
      debugPrint(
        'Bookmark status error: $e',
      );

      if (!mounted) return;

      setState(() {
        _bookmarkLoading = false;
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_bookmarkLoading) return;

    setState(() {
      _bookmarkLoading = true;
    });

    try {
      final result =
      await _service.toggleBookmarkRealtime(
        question.id,
      );

      if (!mounted) return;

      setState(() {
        _isBookmarked = result;
        _bookmarkLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 1),
          content: Text(
            result
                ? 'Question bookmarked'
                : 'Bookmark removed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _bookmarkLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bookmark error: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // 📅 DATE
  // =========================================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Time unavailable';
    }

    final date =
    timestamp.toDate().toLocal();

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    final hour =
    date.hour.toString().padLeft(2, '0');

    final minute =
    date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year • $hour:$minute';
  }

  // =========================================================
  // 👤 ROLE NAME
  // =========================================================

  String _roleName(String? role) {
    switch (role) {
      case 'mufti':
        return 'Mufti';

      case 'admin':
        return 'Admin';

      case 'owner':
        return 'Owner';

      case 'admin_or_owner':
        return 'Admin / Owner';

      default:
        return 'Unknown';
    }
  }

  // =========================================================
  // ✏️ EDIT HISTORY
  // =========================================================

  Future<void> _showEditHistory(
      BuildContext context,
      ) async {
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final fonts =
    context.read<FontProvider>();

    final questionFontFamily =
    fonts.resolveFontFamily(
      fonts.questionFont,
    );

    final questionTextStyle =
    theme.textTheme.bodyMedium?.copyWith(
      fontFamily: questionFontFamily,
      fontSize: fonts.fontSize,
      fontWeight: fonts.fontWeight,
      fontStyle: fonts.isItalic
          ? FontStyle.italic
          : FontStyle.normal,
      height: 1.6,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height:
            MediaQuery.of(context).size.height *
                0.82,
            child: Column(
              children: [
                Padding(
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        color:
                        colorScheme.primary,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Edit History',
                        style: theme
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<
                          Map<String, dynamic>>>(
                    stream:
                    FirebaseFirestore
                        .instance
                        .collection(
                      'questions',
                    )
                        .doc(
                      question.id,
                    )
                        .collection(
                      'editHistory',
                    )
                        .orderBy(
                      'editedAt',
                      descending: true,
                    )
                        .snapshots(),
                    builder: (
                        context,
                        snapshot,
                        ) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding:
                            const EdgeInsets.all(
                              24,
                            ),
                            child: Text(
                              'Edit history load nahi ho saki.\n\n'
                                  '${snapshot.error}',
                              textAlign:
                              TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child:
                          CircularProgressIndicator(
                            color:
                            colorScheme.primary,
                          ),
                        );
                      }

                      final docs =
                          snapshot.data?.docs ??
                              [];

                      if (docs.isEmpty) {
                        return Center(
                          child: Padding(
                            padding:
                            const EdgeInsets.all(
                              24,
                            ),
                            child: Column(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 56,
                                  color:
                                  colorScheme
                                      .outline,
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  'No edit history',
                                  style: theme
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  'Is sawal ko abhi edit nahi kiya gaya.',
                                  textAlign:
                                  TextAlign.center,
                                  style: theme
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding:
                        const EdgeInsets.all(16),
                        itemCount:
                        docs.length,
                        itemBuilder:
                            (context, index) {
                          final data =
                          docs[index].data();

                          final oldQuestion =
                              data['oldQuestion']
                                  ?.toString() ??
                                  '';

                          final newQuestion =
                              data['newQuestion']
                                  ?.toString() ??
                                  '';

                          final editedBy =
                              data['editedBy']
                                  ?.toString() ??
                                  'Unknown';

                          final role =
                          data['editorRole']
                              ?.toString();

                          final editedAt =
                          data['editedAt']
                          is Timestamp
                              ? data['editedAt']
                          as Timestamp
                              : null;

                          return Card(
                            margin:
                            const EdgeInsets.only(
                              bottom: 14,
                            ),
                            elevation: 1,
                            child: Padding(
                              padding:
                              const EdgeInsets.all(
                                16,
                              ),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        child: Text(
                                          editedBy
                                              .isNotEmpty
                                              ? editedBy
                                              .substring(
                                            0,
                                            1,
                                          )
                                              .toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Expanded(
                                        child:
                                        Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                          children: [
                                            Text(
                                              editedBy,
                                              style: theme
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 2,
                                            ),
                                            Text(
                                              '${_roleName(role)} • ${_formatDate(editedAt)}',
                                              style: theme
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 16,
                                  ),

                                  Text(
                                    'BEFORE',
                                    style: theme
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      color:
                                      colorScheme
                                          .error,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Container(
                                    width:
                                    double.infinity,
                                    padding:
                                    const EdgeInsets
                                        .all(12),
                                    decoration:
                                    BoxDecoration(
                                      color: colorScheme
                                          .error
                                          .withValues(
                                        alpha: .06,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        12,
                                      ),
                                    ),
                                    child: Text(
                                      oldQuestion,
                                      style:
                                      questionTextStyle,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  Center(
                                    child: Icon(
                                      Icons
                                          .arrow_downward,
                                      color:
                                      colorScheme
                                          .primary,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 14,
                                  ),

                                  Text(
                                    'AFTER',
                                    style: theme
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                      fontWeight:
                                      FontWeight
                                          .bold,
                                      color:
                                      colorScheme
                                          .primary,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  Container(
                                    width:
                                    double.infinity,
                                    padding:
                                    const EdgeInsets
                                        .all(12),
                                    decoration:
                                    BoxDecoration(
                                      color: colorScheme
                                          .primary
                                          .withValues(
                                        alpha: .06,
                                      ),
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        12,
                                      ),
                                    ),
                                    child: Text(
                                      newQuestion,
                                      style:
                                      questionTextStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // ⏳ QUESTION STATUS
  // =========================================================

  Widget _buildQuestionStatus(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    if (question.status == 'new') {
      return _StatusCard(
        icon:
        Icons.hourglass_empty_rounded,
        color:
        colorScheme.primary,
        title:
        'Question Submitted',
        message:
        'Aapka sawal successfully submit ho gaya hai. Abhi Mufti ke jawab ka intezar hai.',
      );
    }

    if (question.status == 'pending') {
      return _StatusCard(
        icon:
        Icons.hourglass_top_rounded,
        color:
        colorScheme.tertiary,
        title:
        'Question Under Review',
        message:
        'Aapka sawal abhi Mufti ke paas hai aur jawab tayyar kiya ja raha hai.',
      );
    }

    return const SizedBox.shrink();
  }

  // =========================================================
  // 📖 ANSWER SECTION
  // =========================================================

  Widget _buildAnswerSection(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final fonts =
    context.watch<FontProvider>();

    // ---------------------------------------------------------
    // ANSWER FONT
    // ---------------------------------------------------------

    final answerFontFamily =
    fonts.resolveFontFamily(
      fonts.answerFont,
    );

    final answerTextStyle =
    theme.textTheme.bodyLarge?.copyWith(
      fontFamily: answerFontFamily,
      fontSize: fonts.fontSize,
      fontWeight: fonts.fontWeight,
      fontStyle: fonts.isItalic
          ? FontStyle.italic
          : FontStyle.normal,
      height: 1.9,
    );

    final answer =
    (question.answer ?? '').trim();

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 30,
        ),

        Text(
          'ANSWER',
          style: theme
              .textTheme
              .labelLarge!
              .copyWith(
            color:
            colorScheme.primary,
            fontWeight:
            FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        Container(
          width: double.infinity,
          padding:
          const EdgeInsets.all(18),
          decoration:
          BoxDecoration(
            color: theme
                .colorScheme
                .surfaceContainerHighest,
            borderRadius:
            BorderRadius.circular(18),
          ),
          child: SelectableText(
            answer.isEmpty
                ? 'Answer not available.'
                : answer,
            style: answerTextStyle,
          ),
        ),

        if ((question.reference ?? '')
            .trim()
            .isNotEmpty) ...[
          const SizedBox(
            height: 30,
          ),

          Text(
            'REFERENCE',
            style: theme
                .textTheme
                .labelLarge!
                .copyWith(
              color:
              colorScheme.tertiary,
              fontWeight:
              FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.all(18),
            decoration:
            BoxDecoration(
              color: colorScheme
                  .tertiary
                  .withValues(
                alpha: .08,
              ),
              borderRadius:
              BorderRadius.circular(18),
              border:
              Border.all(
                color: colorScheme
                    .tertiary
                    .withValues(
                  alpha: .25,
                ),
              ),
            ),
            child: SelectableText(
              question.reference!,
              style: answerTextStyle,
            ),
          ),
        ],

        const SizedBox(
          height: 28,
        ),

        const Divider(),

        const SizedBox(
          height: 18,
        ),

        Row(
          children: [
            CircleAvatar(
              radius: 26,
              child: Text(
                (question.muftiName ??
                    'Mufti')
                    .isNotEmpty
                    ? (question.muftiName ??
                    'Mufti')
                    .substring(
                  0,
                  1,
                )
                    .toUpperCase()
                    : 'M',
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    question.muftiName ??
                        'Mufti',
                    style: theme
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(
                    'Verified Mufti',
                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color:
                      colorScheme.primary,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 28,
        ),

        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.copy,
            ),
            label: const Text(
              'Copy Answer',
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.share,
            ),
            label: const Text(
              'Share',
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // 🎨 BUILD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final fonts =
    context.watch<FontProvider>();

    // ---------------------------------------------------------
    // QUESTION FONT
    // ---------------------------------------------------------

    final questionFontFamily =
    fonts.resolveFontFamily(
      fonts.questionFont,
    );

    final questionTextStyle =
    theme.textTheme.headlineSmall
        ?.copyWith(
      fontFamily:
      questionFontFamily,
      fontSize:
      fonts.fontSize,
      fontWeight:
      fonts.fontWeight,
      fontStyle:
      fonts.isItalic
          ? FontStyle.italic
          : FontStyle.normal,
      height: 1.5,
    );

    final isPublished =
        question.status ==
            'published';

    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title:
        const Text('Question'),

        centerTitle: true,

        actions: [
          IconButton(
            onPressed:
            _bookmarkLoading
                ? null
                : _toggleBookmark,
            tooltip:
            _isBookmarked
                ? 'Remove Bookmark'
                : 'Bookmark',
            icon:
            _bookmarkLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child:
              CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Icon(
              _isBookmarked
                  ? Icons
                  .bookmark_rounded
                  : Icons
                  .bookmark_border_rounded,
            ),
          ),

          const SizedBox(
            width: 6,
          ),
        ],
      ),

      body:
      SingleChildScrollView(
        padding:
        const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =================================================
            // CATEGORY
            // =================================================

            Wrap(
              spacing: 8,
              children: [
                if ((question.category ??
                    '')
                    .isNotEmpty)
                  Chip(
                    label:
                    Text(
                      question.category!,
                    ),
                  ),

                if ((question
                    .subCategory ??
                    '')
                    .isNotEmpty)
                  Chip(
                    label:
                    Text(
                      question.subCategory!,
                    ),
                  ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // =================================================
            // QUESTION
            // =================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children: [
                Text(
                  'QUESTION',
                  style: theme
                      .textTheme
                      .labelLarge!
                      .copyWith(
                    color: theme
                        .colorScheme
                        .primary,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const Spacer(),

                Flexible(
                  child: Text(
                    'By ${question.hideAskedByName ? 'Anonymous' : question.askedBy}',
                    textAlign:
                    TextAlign.right,
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 10,
            ),

            SelectableText(
              question.questionText,
              style:
              questionTextStyle,
            ),

            // =================================================
            // EDIT HISTORY
            // =================================================

            const SizedBox(
              height: 16,
            ),

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
              FirebaseFirestore
                  .instance
                  .collection(
                'questions',
              )
                  .doc(
                question.id,
              )
                  .collection(
                'editHistory',
              )
                  .limit(1)
                  .snapshots(),
              builder:
                  (context, snapshot) {
                if (!snapshot.hasData ||
                    snapshot.data!.docs
                        .isEmpty) {
                  return const SizedBox
                      .shrink();
                }

                return Align(
                  alignment:
                  Alignment.centerRight,
                  child:
                  TextButton(
                    onPressed: () =>
                        _showEditHistory(
                          context,
                        ),
                    style:
                    TextButton
                        .styleFrom(
                      padding:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      minimumSize:
                      Size.zero,
                      tapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,
                    ),
                    child:
                    Text(
                      'Edited',
                      style: theme
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                        color: theme
                            .colorScheme
                            .primary,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),

            // =================================================
            // NEW / PENDING / ANSWERED
            // =================================================

            if (!isPublished) ...[
              const SizedBox(
                height: 14,
              ),

              _buildQuestionStatus(
                context,
              ),
            ],

            // =================================================
            // ANSWER
            // =================================================

            if (isPublished)
              _buildAnswerSection(
                context,
              ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// ⏳ STATUS CARD
// =============================================================

class _StatusCard
    extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.all(18),
      decoration:
      BoxDecoration(
        color: color.withValues(
          alpha: .08,
        ),
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(
            alpha: .20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),

          const SizedBox(
            width: 14,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                    fontWeight:
                    FontWeight.bold,
                    color: color,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  message,
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}