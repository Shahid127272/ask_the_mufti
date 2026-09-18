import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';
import '../../core/constants.dart';

class ReviewsSuggestionsScreen extends StatefulWidget {
  const ReviewsSuggestionsScreen({super.key});

  @override
  State<ReviewsSuggestionsScreen> createState() =>
      _ReviewsSuggestionsScreenState();
}

class _ReviewsSuggestionsScreenState
    extends State<ReviewsSuggestionsScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _reviewController =
  TextEditingController();

  final TextEditingController _suggestionController =
  TextEditingController();

  int _selectedRating = 0;

  bool _submittingReview = false;
  bool _submittingSuggestion = false;

  bool _loadingMyReview = true;
  bool _hasExistingReview = false;

  @override
  void initState() {
    super.initState();
    _loadMyReview();
  }

  // ============================================================
  // LOAD CURRENT USER REVIEW
  // ============================================================

  Future<void> _loadMyReview() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _loadingMyReview = false;
        });
      }
      return;
    }

    try {
      final doc = await _db
          .collection(AppConstants.reviewsCollection)
          .doc(user.uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};

        setState(() {
          _hasExistingReview = true;

          _selectedRating =
              (data['rating'] as num?)?.toInt() ?? 0;

          _reviewController.text =
              data['review']?.toString() ?? '';

          _loadingMyReview = false;
        });
      } else {
        setState(() {
          _hasExistingReview = false;
          _loadingMyReview = false;
        });
      }
    } catch (e) {
      debugPrint('LOAD MY REVIEW ERROR: $e');

      if (!mounted) return;

      setState(() {
        _loadingMyReview = false;
      });
    }
  }

  // ============================================================
  // SUBMIT / UPDATE REVIEW
  // ============================================================

  Future<void> _submitReview() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Review dene ke liye login zaroori hai.',
      );
      return;
    }

    if (_selectedRating < 1 || _selectedRating > 5) {
      _showMessage(
        'Please rating select karein.',
      );
      return;
    }

    final review = _reviewController.text.trim();

    if (review.isEmpty) {
      _showMessage(
        'Please apna review likhein.',
      );
      return;
    }

    if (review.length < 3) {
      _showMessage(
        'Review thoda detail mein likhein.',
      );
      return;
    }

    if (review.length > 1000) {
      _showMessage(
        'Review 1000 characters se zyada nahi ho sakta.',
      );
      return;
    }

    setState(() {
      _submittingReview = true;
    });

    try {
      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final screenName =
      userData['screenName']?.toString().trim();

      final name =
      userData['name']?.toString().trim();

      final displayName =
      (screenName != null && screenName.isNotEmpty)
          ? screenName
          : (name != null && name.isNotEmpty)
          ? name
          : (user.displayName ?? 'User');

      final reviewRef = _db
          .collection(AppConstants.reviewsCollection)
          .doc(user.uid);

      final existingDoc = await reviewRef.get();

      final data = <String, dynamic>{
        'userId': user.uid,
        'userName': displayName,
        'photoUrl': userData['photoUrl'] ?? user.photoURL,
        'rating': _selectedRating,
        'review': review,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (existingDoc.exists) {
        await reviewRef.update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();

        await reviewRef.set(data);
      }

      if (!mounted) return;

      setState(() {
        _hasExistingReview = true;
        _submittingReview = false;
      });

      FocusScope.of(context).unfocus();

      _showMessage(
        existingDoc.exists
            ? 'Aapka review update ho gaya.'
            : 'Aapka review submit ho gaya.',
      );
    } catch (e) {
      debugPrint('SUBMIT REVIEW ERROR: $e');

      if (!mounted) return;

      setState(() {
        _submittingReview = false;
      });

      _showMessage(
        'Review submit nahi ho saka. Please dobara try karein.',
      );
    }
  }

  // ============================================================
  // SUBMIT SUGGESTION
  // ============================================================

  Future<void> _submitSuggestion() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Suggestion dene ke liye login zaroori hai.',
      );
      return;
    }

    final suggestion =
    _suggestionController.text.trim();

    if (suggestion.isEmpty) {
      _showMessage(
        'Please apni suggestion likhein.',
      );
      return;
    }

    if (suggestion.length < 5) {
      _showMessage(
        'Suggestion thodi detail mein likhein.',
      );
      return;
    }

    if (suggestion.length > 2000) {
      _showMessage(
        'Suggestion 2000 characters se zyada nahi ho sakti.',
      );
      return;
    }

    setState(() {
      _submittingSuggestion = true;
    });

    try {
      final userDoc = await _db
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      final userData = userDoc.data() ?? {};

      final screenName =
      userData['screenName']?.toString().trim();

      final name =
      userData['name']?.toString().trim();

      final displayName =
      (screenName != null && screenName.isNotEmpty)
          ? screenName
          : (name != null && name.isNotEmpty)
          ? name
          : (user.displayName ?? 'User');

      await _db
          .collection(
        AppConstants.suggestionsCollection,
      )
          .add({
        'userId': user.uid,
        'userName': displayName,
        'suggestion': suggestion,
        'status': 'new',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _suggestionController.clear();

      setState(() {
        _submittingSuggestion = false;
      });

      FocusScope.of(context).unfocus();

      _showMessage(
        'Aapki suggestion submit ho gayi. JazakAllah khair.',
      );
    } catch (e) {
      debugPrint('SUBMIT SUGGESTION ERROR: $e');

      if (!mounted) return;

      setState(() {
        _submittingSuggestion = false;
      });

      _showMessage(
        'Suggestion submit nahi ho saki. Please dobara try karein.',
      );
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  // ============================================================
  // RATING COLOR
  // ============================================================

  Color _ratingColor(
      ColorScheme colorScheme,
      int rating,
      ) {
    switch (rating) {
      case 1:
        return colorScheme.error;

      case 2:
        return Colors.orange;

      case 3:
        return Colors.amber;

      case 4:
        return Colors.lightGreen;

      case 5:
        return Colors.green;

      default:
        return colorScheme.outline;
    }
  }

  // ============================================================
  // STAR SELECTOR
  // ============================================================

  Widget _ratingSelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aapka Rating',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: List.generate(
            5,
                (index) {
              final rating = index + 1;

              return IconButton(
                tooltip: '$rating Star',
                onPressed: () {
                  setState(() {
                    _selectedRating = rating;
                  });
                },
                icon: Icon(
                  rating <= _selectedRating
                      ? Icons.star
                      : Icons.star_border,
                  size: 34,
                  color: rating <= _selectedRating
                      ? _ratingColor(
                    colorScheme,
                    _selectedRating,
                  )
                      : colorScheme.outline,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REVIEW FORM
  // ============================================================

  Widget _reviewForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loadingMyReview) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: colorScheme.primary,
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star_outline,
                  color: colorScheme.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    _hasExistingReview
                        ? 'Apna Review Update Karein'
                        : 'App Ko Rate Karein',
                    style:
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _ratingSelector(),

            const SizedBox(height: 8),

            TextField(
              controller: _reviewController,
              maxLines: 4,
              maxLength: 1000,
              textCapitalization:
              TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                'App ke baare mein apna experience likhein...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                _submittingReview
                    ? null
                    : _submitReview,
                icon: _submittingReview
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _submittingReview
                      ? 'Submitting...'
                      : _hasExistingReview
                      ? 'Update Review'
                      : 'Submit Review',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUGGESTION FORM
  // ============================================================

  Widget _suggestionForm() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    'Suggestion Dein',
                    style:
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Aapki suggestion sirf app ke Admin/Owner ko dikhai degi.',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _suggestionController,
              maxLines: 5,
              maxLength: 2000,
              textCapitalization:
              TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText:
                'App mein kya improve ya add hona chahiye?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                _submittingSuggestion
                    ? null
                    : _submitSuggestion,
                icon: _submittingSuggestion
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
                    : const Icon(Icons.send),
                label: Text(
                  _submittingSuggestion
                      ? 'Submitting...'
                      : 'Send Suggestion',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REVIEWS HEADER
  // ============================================================

  Widget _reviewsHeader() {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
      ),
      child: Text(
        'User Reviews',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // REVIEW LIST
  // ============================================================

  Widget _reviewList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _db
          .collection(
        AppConstants.reviewsCollection,
      )
          .orderBy(
        'createdAt',
        descending: true,
      )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(30),
            child: Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Reviews load nahi ho sake.',
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        final reviews =
            snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.rate_review_outlined,
                    size: 46,
                    color: colorScheme.outline,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    'Abhi koi review nahi hai.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'Sabse pehla review aap dein!',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: reviews.map(
                (doc) {
              final data = doc.data();

              return _ReviewCard(
                name:
                data['userName']?.toString() ?? 'User',
                photoUrl:
                data['photoUrl']?.toString(),
                rating:
                (data['rating'] as num?)?.toInt() ?? 0,
                review:
                data['review']?.toString() ?? '',
                createdAt:
                data['createdAt'] as Timestamp?,
              );
            },
          ).toList(),
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      notificationCount: 0,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Reviews & Suggestions',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Apna feedback dein aur app ko behtar banane mein hamari madad karein.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),

          const SizedBox(height: 20),

          _reviewForm(),

          _suggestionForm(),

          _reviewsHeader(),

          _reviewList(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }
}

// ============================================================
// REVIEW CARD
// ============================================================

class _ReviewCard extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final int rating;
  final String review;
  final Timestamp? createdAt;

  const _ReviewCard({
    required this.name,
    this.photoUrl,
    required this.rating,
    required this.review,
    this.createdAt,
  });

  Color _ratingColor(
      ColorScheme colorScheme,
      int rating,
      ) {
    switch (rating) {
      case 1:
        return colorScheme.error;

      case 2:
        return Colors.orange;

      case 3:
        return Colors.amber;

      case 4:
        return Colors.lightGreen;

      case 5:
        return Colors.green;

      default:
        return colorScheme.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final dateText =
    createdAt != null
        ? _formatDate(createdAt!)
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                  photoUrl != null &&
                      photoUrl!.isNotEmpty
                      ? NetworkImage(photoUrl!)
                      : null,
                  child:
                  photoUrl == null ||
                      photoUrl!.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: theme
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Row(
                        children:
                        List.generate(
                          5,
                              (index) {
                            return Icon(
                              index < rating
                                  ? Icons.star
                                  : Icons.star_border,
                              size: 18,
                              color: index < rating
                                  ? _ratingColor(
                                colorScheme,
                                rating,
                              )
                                  : colorScheme.outline,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                if (dateText.isNotEmpty)
                  Text(
                    dateText,
                    style:
                    theme.textTheme.bodySmall,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              review,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(
      Timestamp timestamp) {
    final date = timestamp.toDate();

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    return '$day/$month/$year';
  }
}