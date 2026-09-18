import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  final TextEditingController _controller =
  TextEditingController();

  Timer? _searchDebounce;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    _controller.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 250),
          () {
        if (!mounted) return;

        setState(() {
          _searchQuery = _controller.text.trim();
        });
      },
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  // ============================================================
  // TEXT NORMALIZATION
  // ============================================================

  String _normalizeText(String text) {
    String value = text.toLowerCase().trim();

    // Remove Arabic/Urdu harakaat / tashkeel.
    value = value.replaceAll(
      RegExp(
        r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
      ),
      '',
    );

    // Arabic / Urdu character normalization.
    value = value
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ٱ', 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ی')
        .replaceAll('ى', 'ی')
        .replaceAll('ے', 'ی');

    // Remove punctuation and symbols.
    value = value.replaceAll(
      RegExp(
        r'''[!"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~،؛؟۔«»“”‘’]''',
      ),
      ' ',
    );

    // Multiple spaces -> one space.
    value = value.replaceAll(RegExp(r'\s+'), ' ');

    return value.trim();
  }

  // ============================================================
  // SEARCH MATCH
  // ============================================================

  bool _matchesSearch(
      QuestionModel question,
      String query,
      ) {
    if (query.trim().isEmpty) {
      return true;
    }

    final searchableText = _normalizeText(
      [
        question.questionText,
        question.answer?.toString() ?? '',
        question.category ?? '',
        question.subCategory ?? '',
      ].join(' '),
    );

    final normalizedQuery = _normalizeText(query);

    if (normalizedQuery.isEmpty) {
      return true;
    }

    // Exact phrase match.
    if (searchableText.contains(normalizedQuery)) {
      return true;
    }

    // Multiple-word search.
    //
    // Example:
    // "namaz ke baad"
    //
    // Har word ko separately search kiya jayega.
    final queryWords = normalizedQuery
        .split(' ')
        .where((word) => word.length >= 2)
        .toList();

    if (queryWords.isEmpty) {
      return false;
    }

    // All entered words must exist.
    return queryWords.every(
          (word) => searchableText.contains(word),
    );
  }

  // ============================================================
  // FILTER QUESTIONS
  // ============================================================

  List<QuestionModel> _filterQuestions(
      List<QuestionModel> questions,
      ) {
    if (_searchQuery.isEmpty) {
      return questions;
    }

    return questions.where(
          (question) {
        return _matchesSearch(
          question,
          _searchQuery,
        );
      },
    ).toList();
  }

  // ============================================================
  // CLEAR SEARCH
  // ============================================================

  void _clearSearch() {
    _controller.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          0,
        ),
        child: Column(
          children: [
            // ======================================================
            // SEARCH FIELD
            // ======================================================

            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText:
                'Search questions or answers...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon:
                _controller.text.isNotEmpty
                    ? IconButton(
                  tooltip: 'Clear',
                  onPressed: _clearSearch,
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                filled: true,
                fillColor: colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ======================================================
            // PUBLISHED QUESTIONS
            // ======================================================

            Expanded(
              child: StreamBuilder<List<QuestionModel>>(
                stream: _service.streamPublishedQuestions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize:
                          MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color:
                              colorScheme.error,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Something went wrong',
                              style: theme
                                  .textTheme
                                  .titleMedium,
                              textAlign:
                              TextAlign.center,
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Please try again later.',
                              style: theme
                                  .textTheme
                                  .bodyMedium,
                              textAlign:
                              TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final allQuestions =
                      snapshot.data ?? [];

                  // ------------------------------------------------
                  // EMPTY INITIAL STATE
                  // ------------------------------------------------

                  if (_searchQuery.isEmpty) {
                    return _EmptySearchState(
                      icon: Icons.search,
                      title:
                      'Search for a question',
                      message:
                      'Type a word or phrase to find questions and answers.',
                    );
                  }

                  final results =
                  _filterQuestions(allQuestions);

                  // ------------------------------------------------
                  // NO RESULTS
                  // ------------------------------------------------

                  if (results.isEmpty) {
                    return _EmptySearchState(
                      icon: Icons.search_off,
                      title:
                      'No questions found',
                      message:
                      'Try another word or a different spelling.',
                    );
                  }

                  // ------------------------------------------------
                  // RESULTS
                  // ------------------------------------------------

                  return Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.only(
                          left: 4,
                          bottom: 8,
                        ),
                        child: Text(
                          '${results.length} result${results.length == 1 ? '' : 's'} found',
                          style: theme
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                            fontWeight:
                            FontWeight.w600,
                            color:
                            colorScheme.primary,
                          ),
                        ),
                      ),

                      Expanded(
                        child: ListView.builder(
                          physics:
                          const AlwaysScrollableScrollPhysics(),
                          padding:
                          const EdgeInsets.only(
                            bottom: 24,
                          ),
                          itemCount:
                          results.length,
                          itemBuilder:
                              (context, index) {
                            final question =
                            results[index];

                            return _SearchResultCard(
                              question: question,
                              searchQuery:
                              _searchQuery,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// SEARCH RESULT CARD
// ================================================================

class _SearchResultCard extends StatelessWidget {
  final QuestionModel question;
  final String searchQuery;

  const _SearchResultCard({
    required this.question,
    required this.searchQuery,
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

    final answerFontFamily =
    fonts.resolveFontFamily(
      fonts.answerFont,
    );

    final category =
        question.category?.trim() ?? '';

    final subCategory =
        question.subCategory?.trim() ?? '';

    String categoryText = '';

    if (category.isNotEmpty &&
        subCategory.isNotEmpty) {
      categoryText =
      '$category • $subCategory';
    } else if (category.isNotEmpty) {
      categoryText = category;
    } else if (subCategory.isNotEmpty) {
      categoryText = subCategory;
    }

    final answer =
        question.answer?.toString().trim() ?? '';

    return Card(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: theme.dividerColor,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AnswerDetailScreen(
                    question: question,
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ----------------------------------------------------
              // QUESTION
              // ----------------------------------------------------

              Text(
                question.questionText,
                maxLines: 3,
                overflow:
                TextOverflow.ellipsis,
                style: theme
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontFamily:
                  questionFontFamily,
                  fontWeight:
                  FontWeight.w700,
                  height: 1.45,
                ),
              ),

              // ----------------------------------------------------
              // ANSWER PREVIEW
              // ----------------------------------------------------

              if (answer.isNotEmpty) ...[
                const SizedBox(height: 8),

                Text(
                  answer,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                    fontFamily:
                    answerFontFamily,
                    color: theme
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withValues(
                      alpha: 0.75,
                    ),
                    height: 1.4,
                  ),
                ),
              ],

              // ----------------------------------------------------
              // CATEGORY
              // ----------------------------------------------------

              if (categoryText.isNotEmpty) ...[
                const SizedBox(height: 10),

                Text(
                  categoryText,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: theme
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                    fontWeight:
                    FontWeight.w500,
                    color:
                    colorScheme.primary,
                  ),
                ),
              ],

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color:
                    colorScheme.primary,
                  ),

                  const SizedBox(width: 5),

                  Text(
                    'View Answer',
                    style: theme
                        .textTheme
                        .labelMedium
                        ?.copyWith(
                      fontWeight:
                      FontWeight.w600,
                      color:
                      colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY SEARCH STATE
// ================================================================

class _EmptySearchState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptySearchState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 58,
              color: colorScheme.primary
                  .withValues(alpha: 0.55),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: theme
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight:
                FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              message,
              style: theme
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: theme
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(
                  alpha: 0.7,
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}