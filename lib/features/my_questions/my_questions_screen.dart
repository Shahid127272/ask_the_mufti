import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class MyQuestionsScreen extends StatefulWidget {
  const MyQuestionsScreen({super.key});

  @override
  State<MyQuestionsScreen> createState() =>
      _MyQuestionsScreenState();
}

class _MyQuestionsScreenState
    extends State<MyQuestionsScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  int _selectedTab = 0;

  // =========================================================
  // TABS
  // =========================================================

  final List<String> _tabs = const [
    'All',
    'New Questions',
    'Pending',
    'Answered',
    'Bookmark',
  ];

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      notificationCount: 0,

      body: StreamBuilder<List<QuestionModel>>(
        stream: _service.watchMyQuestions(),

        builder: (context, snapshot) {
          // ---------------------------------------------------
          // LOADING
          // ---------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ---------------------------------------------------
          // ERROR
          // ---------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Questions load nahi ho sake.\n\n'
                      '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final myQuestions =
              snapshot.data ?? [];

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // =================================================
              // TITLE
              // =================================================

              Padding(
                padding:
                const EdgeInsets.fromLTRB(
                  16,
                  14,
                  16,
                  4,
                ),
                child: Text(
                  'My Questions',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
              ),

              // =================================================
              // TABS
              // =================================================

              _buildTabs(),

              // =================================================
              // CONTENT
              // =================================================

              Expanded(
                child: _selectedTab == 4
                    ? _buildBookmarkTab()
                    : _buildMyQuestionTab(
                  myQuestions,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // 🔘 TABS
  // =========================================================

  Widget _buildTabs() {
    final theme =
    Theme.of(context);

    return SizedBox(
      height: 54,

      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,

        padding:
        const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),

        itemCount:
        _tabs.length,

        separatorBuilder:
            (_, __) =>
        const SizedBox(
          width: 8,
        ),

        itemBuilder:
            (context, index) {
          final selected =
              _selectedTab == index;

          return ChoiceChip(
            label:
            Text(_tabs[index]),

            selected:
            selected,

            onSelected:
                (_) {
              setState(() {
                _selectedTab =
                    index;
              });
            },

            selectedColor:
            theme.colorScheme.primary,

            labelStyle:
            TextStyle(
              color: selected
                  ? theme
                  .colorScheme
                  .onPrimary
                  : theme
                  .colorScheme
                  .onSurface,

              fontWeight: selected
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // 👤 MY QUESTIONS
  // =========================================================

  Widget _buildMyQuestionTab(
      List<QuestionModel> questions,
      ) {
    final filtered =
    _filterQuestions(
      questions,
    );

    // ---------------------------------------------------------
    // EMPTY
    // ---------------------------------------------------------

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon:
        Icons.question_answer_outlined,
        title:
        _emptyTitle(),
        subtitle:
        _emptySubtitle(),
      );
    }

    // ---------------------------------------------------------
    // LIST
    // ---------------------------------------------------------

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});

        await Future.delayed(
          const Duration(
            milliseconds: 300,
          ),
        );
      },

      child: ListView.builder(
        physics:
        const AlwaysScrollableScrollPhysics(),

        padding:
        const EdgeInsets.only(
          top: 4,
          bottom: 24,
        ),

        itemCount:
        filtered.length,

        itemBuilder:
            (context, index) {
          return _QuestionCard(
            question:
            filtered[index],
          );
        },
      ),
    );
  }

  // =========================================================
  // 🔖 BOOKMARKS
  // =========================================================

  Widget _buildBookmarkTab() {
    return StreamBuilder<
        List<QuestionModel>>(
      stream:
      _service.getBookmarkedQuestions(),

      builder:
          (context, snapshot) {
        // -----------------------------------------------------
        // LOADING
        // -----------------------------------------------------

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child:
            CircularProgressIndicator(),
          );
        }

        // -----------------------------------------------------
        // ERROR
        // -----------------------------------------------------

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding:
              const EdgeInsets.all(20),
              child: Text(
                'Bookmarks load nahi ho sake.\n\n'
                    '${snapshot.error}',
                textAlign:
                TextAlign.center,
              ),
            ),
          );
        }

        final questions =
            snapshot.data ?? [];

        // -----------------------------------------------------
        // EMPTY
        // -----------------------------------------------------

        if (questions.isEmpty) {
          return _buildEmptyState(
            icon:
            Icons.bookmark_border_rounded,
            title:
            'No Bookmarks',
            subtitle:
            'Aapke bookmarked questions yahan dikhenge.',
          );
        }

        // -----------------------------------------------------
        // BOOKMARK LIST
        // -----------------------------------------------------

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});

            await Future.delayed(
              const Duration(
                milliseconds: 300,
              ),
            );
          },

          child: ListView.builder(
            physics:
            const AlwaysScrollableScrollPhysics(),

            padding:
            const EdgeInsets.only(
              top: 4,
              bottom: 24,
            ),

            itemCount:
            questions.length,

            itemBuilder:
                (context, index) {
              return _QuestionCard(
                question:
                questions[index],
              );
            },
          ),
        );
      },
    );
  }

  // =========================================================
  // 🔍 FILTER
  // =========================================================

  List<QuestionModel> _filterQuestions(
      List<QuestionModel> questions,
      ) {
    switch (_selectedTab) {
    // -------------------------------------------------------
    // NEW QUESTIONS
    // -------------------------------------------------------

      case 1:
        return questions
            .where(
              (q) => q.status == 'new',
        )
            .toList();

    // -------------------------------------------------------
    // PENDING
    // -------------------------------------------------------

      case 2:
        return questions
            .where(
              (q) => q.status == 'pending',
        )
            .toList();

    // -------------------------------------------------------
    // ANSWERED
    // -------------------------------------------------------

      case 3:
        return questions
            .where(
              (q) => q.status == 'published',
        )
            .toList();

    // -------------------------------------------------------
    // ALL
    // -------------------------------------------------------

      case 0:
      default:
        return questions;
    }
  }

  // =========================================================
  // 📭 EMPTY TITLE
  // =========================================================

  String _emptyTitle() {
    switch (_selectedTab) {
      case 1:
        return 'No New Questions';

      case 2:
        return 'No Pending Questions';

      case 3:
        return 'No Answered Questions';

      case 4:
        return 'No Bookmarks';

      case 0:
      default:
        return 'No Questions';
    }
  }

  // =========================================================
  // 📭 EMPTY SUBTITLE
  // =========================================================

  String _emptySubtitle() {
    switch (_selectedTab) {
      case 1:
        return 'Aapke naye questions yahan dikhai denge.';

      case 2:
        return 'Aapke pending questions yahan dikhai denge.';

      case 3:
        return
          'Jin questions ka jawab aa gaya hai, '
              'woh yahan dikhai denge.';

      case 4:
        return
          'Aapke bookmarked questions yahan dikhai denge.';

      case 0:
      default:
        return 'Aapke questions yahan dikhai denge.';
    }
  }

  // =========================================================
  // 📭 EMPTY STATE
  // =========================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme =
    Theme.of(context);

    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(24),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Icon(
              icon,
              size: 60,
              color:
              theme
                  .colorScheme
                  .outline,
            ),

            const SizedBox(
              height: 14,
            ),

            Text(
              title,
              textAlign:
              TextAlign.center,

              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            Text(
              subtitle,
              textAlign:
              TextAlign.center,

              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: theme
                    .colorScheme
                    .onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// 📝 QUESTION CARD
// =============================================================

class _QuestionCard
    extends StatefulWidget {
  final QuestionModel question;

  const _QuestionCard({
    required this.question,
  });

  @override
  State<_QuestionCard> createState() =>
      _QuestionCardState();
}

class _QuestionCardState
    extends State<_QuestionCard> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  bool _isBookmarked = false;
  bool _bookmarkLoading = true;

  QuestionModel get question =>
      widget.question;

  // =========================================================
  // 🔖 LOAD BOOKMARK STATUS
  // =========================================================

  @override
  void initState() {
    super.initState();

    _loadBookmarkStatus();
  }

  Future<void> _loadBookmarkStatus() async {
    try {
      final result =
      await _service.isBookmarkedByUser(
        question.id,
      );

      if (!mounted) return;

      setState(() {
        _isBookmarked = result;
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

  // =========================================================
  // 🔖 TOGGLE BOOKMARK
  // =========================================================

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

      // -------------------------------------------------------
      // BOOKMARK TAB MEIN REMOVE KARNE PAR
      // card khud remove hone ke liye parent stream update hoga.
      // -------------------------------------------------------
    } catch (e) {
      debugPrint(
        'Bookmark toggle error: $e',
      );

      if (!mounted) return;

      setState(() {
        _bookmarkLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text(
            'Bookmark update nahi ho saka.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // 📅 DATE
  // =========================================================

  String _formatDate(
      Timestamp timestamp,
      ) {
    final date =
    timestamp.toDate().toLocal();

    final day =
    date.day.toString().padLeft(
      2,
      '0',
    );

    final month =
    date.month.toString().padLeft(
      2,
      '0',
    );

    final year =
    date.year.toString();

    return '$day/$month/$year';
  }

  // =========================================================
  // 🏷️ STATUS INFO
  // =========================================================

  (String, Color, IconData) _statusInfo(
      String status,
      ThemeData theme,
      ) {
    switch (status) {
      case 'published':
        return (
        'Answered',
        Colors.green,
        Icons.check_circle_rounded,
        );

      case 'pending':
        return (
        'Pending',
        Colors.orange,
        Icons.hourglass_top_rounded,
        );

      case 'new':
        return (
        'New',
        theme.colorScheme.primary,
        Icons.fiber_new_rounded,
        );

      case 'rejected':
        return (
        'Rejected',
        Colors.red,
        Icons.cancel_rounded,
        );

      default:
        return (
        status,
        theme.colorScheme.outline,
        Icons.info_outline_rounded,
        );
    }
  }

  // =========================================================
  // 🎨 BUILD CARD
  // =========================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final theme =
    Theme.of(context);

    final statusInfo =
    _statusInfo(
      question.status,
      theme,
    );

    final category =
        question.category
            ?.trim() ??
            '';

    final subCategory =
        question.subCategory
            ?.trim() ??
            '';

    String categoryText = '';

    if (category.isNotEmpty &&
        subCategory.isNotEmpty) {
      categoryText =
      '$category • $subCategory';
    } else if (category.isNotEmpty) {
      categoryText =
          category;
    } else if (subCategory.isNotEmpty) {
      categoryText =
          subCategory;
    }

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AnswerDetailScreen(
                    question:
                    question,
                  ),
            ),
          );
        },

        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 13,
          ),

          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              // =================================================
              // QUESTION + BOOKMARK
              // =================================================

              Row(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,

                children: [
                  Expanded(
                    child: Text(
                      question.questionText,

                      maxLines: 3,

                      overflow:
                      TextOverflow.ellipsis,

                      style: theme
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight:
                        FontWeight.bold,
                        height: 1.45,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // ------------------------------------------------
                  // BOOKMARK BUTTON
                  // ------------------------------------------------

                  IconButton(
                    onPressed:
                    _bookmarkLoading
                        ? null
                        : _toggleBookmark,

                    tooltip:
                    _isBookmarked
                        ? 'Remove Bookmark'
                        : 'Bookmark',

                    padding:
                    EdgeInsets.zero,

                    constraints:
                    const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),

                    icon:
                    _bookmarkLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                      CircularProgressIndicator(
                        strokeWidth:
                        2,
                      ),
                    )
                        : Icon(
                      _isBookmarked
                          ? Icons
                          .bookmark_rounded
                          : Icons
                          .bookmark_border_rounded,

                      color:
                      _isBookmarked
                          ? theme
                          .colorScheme
                          .primary
                          : theme
                          .colorScheme
                          .outline,
                    ),
                  ),
                ],
              ),

              // =================================================
              // CATEGORY
              // =================================================

              if (categoryText.isNotEmpty) ...[
                const SizedBox(
                  height: 6,
                ),

                Text(
                  categoryText,

                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    color: theme
                        .colorScheme
                        .onSurfaceVariant,
                  ),
                ),
              ],

              // =================================================
              // STATUS + MUFTI
              // =================================================

              const SizedBox(
                height: 8,
              ),

              Row(
                children: [
                  _StatusBadge(
                    text:
                    statusInfo.$1,
                    color:
                    statusInfo.$2,
                    icon:
                    statusInfo.$3,
                  ),

                  // ---------------------------------------------
                  // MUFTI NAME ONLY FOR ANSWERED
                  // ---------------------------------------------

                  if (question.status ==
                      'published' &&
                      question.muftiName !=
                          null &&
                      question.muftiName!
                          .trim()
                          .isNotEmpty) ...[
                    const SizedBox(
                      width: 8,
                    ),

                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons
                                .verified_rounded,
                            size: 15,
                            color:
                            Colors.green,
                          ),

                          const SizedBox(
                            width: 4,
                          ),

                          Expanded(
                            child: Text(
                              'Answered by ${question.muftiName}',

                              maxLines: 1,

                              overflow:
                              TextOverflow
                                  .ellipsis,

                              style: theme
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                color:
                                Colors.green,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              // =================================================
              // DATE
              // =================================================

              const SizedBox(
                height: 9,
              ),

              Row(
                children: [
                  Icon(
                    Icons
                        .access_time_rounded,
                    size: 14,
                    color: theme
                        .colorScheme
                        .outline,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    _formatDate(
                      question.updatedAt ??
                          question.createdAt,
                    ),

                    style: theme
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                      color: theme
                          .colorScheme
                          .onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  const Icon(
                    Icons
                        .arrow_forward_ios_rounded,
                    size: 13,
                  ),
                ],
              ),

              const SizedBox(
                height: 12,
              ),

              const Divider(
                height: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// 🏷️ STATUS BADGE
// =============================================================

class _StatusBadge
    extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.text,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),

      decoration:
      BoxDecoration(
        color:
        color.withValues(
          alpha: .10,
        ),

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),

      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),

          const SizedBox(
            width: 4,
          ),

          Text(
            text,

            style: TextStyle(
              fontSize: 11,
              fontWeight:
              FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}