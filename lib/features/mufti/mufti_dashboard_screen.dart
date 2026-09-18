import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';
import 'answer_question_screen.dart';

class MuftiDashboardScreen extends StatefulWidget {
  const MuftiDashboardScreen({super.key});

  @override
  State<MuftiDashboardScreen> createState() =>
      _MuftiDashboardScreenState();
}

class _MuftiDashboardScreenState
    extends State<MuftiDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final QuestionsFirestoreService service =
  QuestionsFirestoreService();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 4,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // =========================================================
  // 🆕 NEW QUESTIONS
  // =========================================================

  Query<Map<String, dynamic>> _newQuestions() {
    return FirebaseFirestore.instance
        .collection('questions')
        .where(
      'status',
      isEqualTo: 'new',
    )
        .orderBy(
      'createdAt',
      descending: true,
    );
  }

  // =========================================================
  // ⏳ PENDING QUESTIONS
  // =========================================================

  Query<Map<String, dynamic>> _pendingQuestions() {
    return FirebaseFirestore.instance
        .collection('questions')
        .where(
      'status',
      isEqualTo: 'pending',
    )
        .orderBy(
      'createdAt',
      descending: true,
    );
  }

  // =========================================================
  // ✅ ANSWERED QUESTIONS
  // =========================================================

  Query<Map<String, dynamic>> _answeredQuestions() {
    return FirebaseFirestore.instance
        .collection('questions')
        .where(
      'status',
      isEqualTo: 'published',
    )
        .orderBy(
      'updatedAt',
      descending: true,
    );
  }

  // =========================================================
  // 👤 MY ANSWERS
  // =========================================================

  Query<Map<String, dynamic>> _myAnswers() {
    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    return FirebaseFirestore.instance
        .collection('questions')
        .where(
      'muftiId',
      isEqualTo: uid,
    )
        .orderBy(
      'updatedAt',
      descending: true,
    );
  }

  // =========================================================
  // 📋 BUILD QUESTION LIST
  // =========================================================

  Widget _buildList(
      Query<Map<String, dynamic>> query, {
        required bool showClaimSystem,
      }) {
    final theme = Theme.of(context);

    final fonts =
    context.watch<FontProvider>();

    final role =
        context.watch<RoleViewController>().activeRole;

    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    final canDelete =
        role == 'admin' ||
            role == 'owner';

    final isMufti =
        role == 'mufti';

    final questionTextStyle =
    theme.textTheme.titleMedium?.copyWith(
      fontFamily:
      fonts.resolveFontFamily(
        fonts.questionFont,
      ),
      fontSize:
      fonts.fontSize,
      fontWeight:
      fonts.fontWeight,
      fontStyle:
      fonts.isItalic
          ? FontStyle.italic
          : FontStyle.normal,
    );

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // =====================================================
        // LOADING
        // =====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color:
              theme.colorScheme.primary,
            ),
          );
        }

        // =====================================================
        // ERROR
        // =====================================================

        if (snapshot.hasError) {
          debugPrint(
            snapshot.error.toString(),
          );

          return Center(
            child: Text(
              'Unable to load questions',
              style:
              theme.textTheme.bodyMedium,
            ),
          );
        }

        // =====================================================
        // DOCUMENTS
        // =====================================================

        final docs =
            snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No questions',
              style:
              theme.textTheme.bodyMedium,
            ),
          );
        }

        // =====================================================
        // LIST
        // =====================================================

        return ListView.builder(
          padding:
          const EdgeInsets.all(12),
          itemCount:
          docs.length,
          itemBuilder:
              (context, index) {
            final doc =
            docs[index];

            final question =
            QuestionModel.fromFirestore(
              doc,
            );

            // =================================================
            // CLAIM STATUS
            // =================================================

            final hasActiveClaim =
                question.hasActiveClaim;

            final claimedByCurrentUser =
            question.isClaimedBy(
              currentUid,
            );

            final hasExpiredClaim =
                question.isClaimed &&
                    question.isClaimExpired;

            return Card(
              elevation: 2,
              margin:
              const EdgeInsets.only(
                bottom: 10,
              ),
              child: Padding(
                padding:
                const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // =========================================
                    // QUESTION AREA
                    // =========================================

                    InkWell(
                      borderRadius:
                      BorderRadius.circular(8),

                      onTap: () async {
                        // =======================================
                        // NEW → PENDING
                        //
                        // IMPORTANT:
                        // Open karne wale Mufti ko claim
                        // automatically nahi milega.
                        // =======================================

                        if (question.status ==
                            'new') {
                          try {
                            await service
                                .markAsPending(
                              question.id,
                            );

                            if (!context
                                .mounted) {
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AnswerQuestionScreen(
                                      question:
                                      question,
                                    ),
                              ),
                            );
                          } catch (e) {
                            if (!context
                                .mounted) {
                              return;
                            }

                            ScaffoldMessenger
                                .of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString()
                                      .replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }

                          return;
                        }

                        // =======================================
                        // PENDING
                        // =======================================

                        if (question.status ==
                            'pending') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnswerQuestionScreen(
                                    question:
                                    question,
                                  ),
                            ),
                          );

                          return;
                        }

                        // =======================================
                        // PUBLISHED
                        // =======================================

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

                      child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question
                                      .questionText,
                                  maxLines: 3,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  questionTextStyle,
                                ),

                                const SizedBox(
                                  height: 6,
                                ),

                                Row(
                                  children: [
                                    Text(
                                      question
                                          .status
                                          .toUpperCase(),
                                      style: theme
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                        color: theme
                                            .colorScheme
                                            .primary,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),

                                    if (question
                                        .category
                                        ?.isNotEmpty ==
                                        true) ...[
                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Text(
                                        '•',
                                        style: theme
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .outlineVariant,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      Expanded(
                                        child:
                                        Text(
                                          question
                                              .category!,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow
                                              .ellipsis,
                                          style: theme
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(
                            width: 8,
                          ),

                          Icon(
                            Icons
                                .arrow_forward_ios,
                            size: 16,
                            color: theme
                                .colorScheme
                                .primary,
                          ),
                        ],
                      ),
                    ),

                    // =========================================
                    // CLAIM SYSTEM
                    //
                    // Sirf New / Pending mein
                    // aur sirf Mufti ko.
                    // =========================================

                    if (showClaimSystem &&
                        isMufti) ...[
                      const SizedBox(
                        height: 12,
                      ),

                      const Divider(
                        height: 1,
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      // =======================================
                      // NO ACTIVE CLAIM
                      //
                      // Unclaimed ya expired:
                      // CLAIM button
                      // =======================================

                      if (!hasActiveClaim) ...[
                        SizedBox(
                          width:
                          double.infinity,
                          child:
                          ElevatedButton(
                            onPressed:
                                () async {
                              try {
                                await service
                                    .claimQuestion(
                                  question.id,
                                );

                                if (!context
                                    .mounted) {
                                  return;
                                }

                                ScaffoldMessenger
                                    .of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content:
                                    Text(
                                      'Question claimed successfully.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context
                                    .mounted) {
                                  return;
                                }

                                ScaffoldMessenger
                                    .of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                    Text(
                                      e.toString()
                                          .replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child:
                            const Text(
                              'CLAIM',
                            ),
                          ),
                        ),

                        if (hasExpiredClaim) ...[
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Previous claim expired. This question is available again.',
                            style: theme
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                              fontSize: 12,
                              color: theme
                                  .colorScheme
                                  .error,
                            ),
                          ),
                        ],
                      ]

                      // =======================================
                      // CURRENT MUFTI CLAIMED
                      //
                      // Sirf jis Mufti ne claim kiya:
                      // Submit Answer + Unclaim
                      // =======================================

                      else if (
                      claimedByCurrentUser) ...[
                          Row(
                            children: [
                              // =================================
                              // SUBMIT ANSWER
                              // =================================

                              Expanded(
                                child:
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AnswerQuestionScreen(
                                              question:
                                              question,
                                            ),
                                      ),
                                    );
                                  },
                                  child:
                                  const Text(
                                    'Submit Answer',
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              // =================================
                              // UNCLAIM
                              // =================================

                              Expanded(
                                child:
                                OutlinedButton(
                                  onPressed:
                                      () async {
                                    final confirm =
                                    await showDialog<
                                        bool>(
                                      context:
                                      context,
                                      builder:
                                          (_) =>
                                          AlertDialog(
                                            title:
                                            const Text(
                                              'Unclaim Question',
                                            ),
                                            content:
                                            const Text(
                                              'Are you sure you want to unclaim this question?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () {
                                                  Navigator.pop(
                                                    context,
                                                    false,
                                                  );
                                                },
                                                child:
                                                const Text(
                                                  'Cancel',
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed:
                                                    () {
                                                  Navigator.pop(
                                                    context,
                                                    true,
                                                  );
                                                },
                                                child:
                                                const Text(
                                                  'Unclaim',
                                                ),
                                              ),
                                            ],
                                          ),
                                    );

                                    if (confirm !=
                                        true) {
                                      return;
                                    }

                                    try {
                                      await service
                                          .unclaimQuestion(
                                        question.id,
                                      );

                                      if (!context
                                          .mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger
                                          .of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                          Text(
                                            'Question unclaimed.',
                                          ),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context
                                          .mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger
                                          .of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content:
                                          Text(
                                            e.toString()
                                                .replaceFirst(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  child:
                                  const Text(
                                    'Unclaim',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          if (question
                              .claimExpiresAt !=
                              null)
                            _ClaimExpiryText(
                              expiresAt:
                              question
                                  .claimExpiresAt!,
                            ),
                        ]

                      // =======================================
                      // OTHER MUFTI CLAIMED
                      //
                      // Baqi Muftiyon ko sirf:
                      // CLAIMED
                      //
                      // Button nahi.
                      // =======================================

                      else ...[
                          Container(
                            width:
                            double.infinity,
                            padding:
                            const EdgeInsets
                                .symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                            decoration:
                            BoxDecoration(
                              color: theme
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                              BorderRadius
                                  .circular(
                                8,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons
                                      .lock_outline,
                                  size: 18,
                                ),

                                const SizedBox(
                                  width: 8,
                                ),

                                Expanded(
                                  child:
                                  Text(
                                    'CLAIMED',
                                    style:
                                    TextStyle(
                                      fontWeight:
                                      FontWeight
                                          .w600,
                                      color: theme
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                    ],

                    // =========================================
                    // ADMIN / OWNER DELETE
                    // =========================================

                    if (canDelete) ...[
                      const SizedBox(
                        height: 8,
                      ),

                      Align(
                        alignment:
                        Alignment.centerRight,
                        child:
                        IconButton(
                          tooltip:
                          'Delete Question',
                          icon: Icon(
                            Icons.delete,
                            color: theme
                                .colorScheme
                                .error,
                          ),
                          onPressed:
                              () async {
                            final confirm =
                            await showDialog<
                                bool>(
                              context:
                              context,
                              builder: (_) =>
                                  AlertDialog(
                                    title:
                                    const Text(
                                      'Delete',
                                    ),
                                    content:
                                    const Text(
                                      'Delete this question?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () {
                                          Navigator.pop(
                                            context,
                                            false,
                                          );
                                        },
                                        child:
                                        const Text(
                                          'Cancel',
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () {
                                          Navigator.pop(
                                            context,
                                            true,
                                          );
                                        },
                                        child:
                                        const Text(
                                          'Delete',
                                        ),
                                      ),
                                    ],
                                  ),
                            );

                            if (confirm !=
                                true) {
                              return;
                            }

                            try {
                              await service
                                  .deleteQuestion(
                                question.id,
                              );

                              if (!context
                                  .mounted) {
                                return;
                              }

                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Question deleted.',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!context
                                  .mounted) {
                                return;
                              }

                              ScaffoldMessenger
                                  .of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                  Text(
                                    e.toString()
                                        .replaceFirst(
                                      'Exception: ',
                                      '',
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================
  // 🏠 BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    return AppScaffold(
      notificationCount: 0,
      body: Column(
        children: [
          // ===================================================
          // TABS
          // ===================================================

          Material(
            color:
            theme.colorScheme.primary,
            child: TabBar(
              controller:
              _tabController,
              isScrollable: true,
              labelColor:
              theme.colorScheme.onPrimary,
              unselectedLabelColor:
              theme.colorScheme.onPrimary
                  .withValues(
                alpha: 0.70,
              ),
              indicatorColor:
              theme.colorScheme.onPrimary,
              tabs: const [
                Tab(
                  text: 'New',
                ),
                Tab(
                  text: 'Pending',
                ),
                Tab(
                  text: 'Answered',
                ),
                Tab(
                  text: 'My Answers',
                ),
              ],
            ),
          ),

          // ===================================================
          // TAB CONTENT
          // ===================================================

          Expanded(
            child: TabBarView(
              controller:
              _tabController,
              children: [
                // NEW
                _buildList(
                  _newQuestions(),
                  showClaimSystem: true,
                ),

                // PENDING
                _buildList(
                  _pendingQuestions(),
                  showClaimSystem: true,
                ),

                // ANSWERED
                _buildList(
                  _answeredQuestions(),
                  showClaimSystem: false,
                ),

                // MY ANSWERS
                _buildList(
                  _myAnswers(),
                  showClaimSystem: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// ⏰ CLAIM EXPIRY TEXT
// =============================================================

class _ClaimExpiryText
    extends StatelessWidget {
  final Timestamp expiresAt;

  const _ClaimExpiryText({
    required this.expiresAt,
  });

  @override
  Widget build(
      BuildContext context,
      ) {
    final remaining =
    expiresAt.toDate().difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining == Duration.zero) {
      final theme =
      Theme.of(context);

      return Text(
        'Claim expired',
        style: theme
            .textTheme
            .bodySmall
            ?.copyWith(
          fontSize: 12,
          color:
          theme.colorScheme.error,
        ),
      );
    }

    final days =
        remaining.inDays;

    final hours =
        remaining.inHours % 24;

    final minutes =
        remaining.inMinutes % 60;

    String text;

    if (days > 0) {
      text =
      'Claim expires in $days day${days == 1 ? '' : 's'}';
    } else if (hours > 0) {
      text =
      'Claim expires in $hours hour${hours == 1 ? '' : 's'}';
    } else {
      text =
      'Claim expires in $minutes minute${minutes == 1 ? '' : 's'}';
    }

    return Text(
      text,
      style:
      Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(
        fontSize: 12,
        color: Theme.of(context)
            .colorScheme
            .tertiary,
        fontWeight:
        FontWeight.w500,
      ),
    );
  }
}