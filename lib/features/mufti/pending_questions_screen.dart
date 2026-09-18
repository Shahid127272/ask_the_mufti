import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/role_view_controller.dart';
import '../../models/question_model.dart';
import '../../providers/font_provider.dart';
import '../../services/questions_firestore_service.dart';
import 'answer_question_screen.dart';

class PendingQuestionsScreen extends StatelessWidget {
  const PendingQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = QuestionsFirestoreService();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fonts = context.watch<FontProvider>();

    final role =
        context.watch<RoleViewController>().activeRole;

    final currentUser =
        FirebaseAuth.instance.currentUser;

    final currentUid =
        currentUser?.uid;

    final isMufti =
        role == 'mufti';

    final questionTextStyle =
    theme.textTheme.bodyLarge?.copyWith(
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pending Questions',
        ),
      ),

      body: StreamBuilder<List<QuestionModel>>(
        stream: service.watchQuestions(
          role: role,
        ),

        builder: (context, snapshot) {
          // =================================================
          // LOADING
          // =================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color:
                colorScheme.primary,
              ),
            );
          }

          // =================================================
          // ERROR
          // =================================================

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

          // =================================================
          // PENDING QUESTIONS
          // =================================================

          final questions =
              snapshot.data
                  ?.where(
                    (q) =>
                q.status == 'pending',
              )
                  .toList() ??
                  [];

          // =================================================
          // EMPTY
          // =================================================

          if (questions.isEmpty) {
            return Center(
              child: Text(
                'No pending questions',
                style: theme
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                  fontSize: 16,
                ),
              ),
            );
          }

          // =================================================
          // LIST
          // =================================================

          return ListView.separated(
            padding:
            const EdgeInsets.all(12),

            itemCount:
            questions.length,

            separatorBuilder:
                (_, __) =>
            const SizedBox(
              height: 8,
            ),

            itemBuilder:
                (context, index) {
              final q =
              questions[index];

              // =================================================
              // CLAIM STATUS
              // =================================================

              final hasActiveClaim =
                  q.hasActiveClaim;

              final claimedByCurrentUser =
              q.isClaimedBy(
                currentUid,
              );

              // =================================================
              // CARD
              // =================================================

              return Card(
                elevation: 2,

                child: Padding(
                  padding:
                  const EdgeInsets.all(
                    12,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      // =========================================
                      // QUESTION
                      // =========================================

                      InkWell(
                        borderRadius:
                        BorderRadius.circular(
                          8,
                        ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AnswerQuestionScreen(
                                    question: q,
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
                                CrossAxisAlignment
                                    .start,

                                children: [
                                  Text(
                                    q.questionText,

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

                                  Text(
                                    q.category ??
                                        'Uncategorized',

                                    style:
                                    theme
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                      fontSize: 12,
                                      color:
                                      colorScheme
                                          .onSurfaceVariant,
                                    ),
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
                              color:
                              colorScheme
                                  .primary,
                            ),
                          ],
                        ),
                      ),

                      // =========================================
                      // CLAIM ACTIONS
                      // =========================================

                      if (isMufti) ...[
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
                        // =======================================

                        if (!hasActiveClaim) ...[
                          SizedBox(
                            width:
                            double.infinity,

                            child:
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await service
                                      .claimQuestion(
                                    q.id,
                                  );

                                  if (!context
                                      .mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                      .of(
                                    context,
                                  ).showSnackBar(
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
                                      .of(
                                    context,
                                  ).showSnackBar(
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

                          // =======================================
                          // CURRENT MUFTI HAS CLAIMED
                          // =======================================

                        ] else if (
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
                                                q,
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
                                          q.id,
                                        );

                                        if (!context
                                            .mounted) {
                                          return;
                                        }

                                        ScaffoldMessenger
                                            .of(
                                          context,
                                        ).showSnackBar(
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
                                            .of(
                                          context,
                                        ).showSnackBar(
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

                            // =================================
                            // EXPIRY
                            // =================================

                            if (q.claimExpiresAt !=
                                null)
                              _ClaimExpiryText(
                                expiresAt:
                                q.claimExpiresAt!,
                              ),

                            // =======================================
                            // OTHER MUFTI HAS CLAIMED
                            // =======================================

                          ] else ...[
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
                                color:
                                colorScheme
                                    .surfaceContainerHighest,

                                borderRadius:
                                BorderRadius
                                    .circular(
                                  8,
                                ),
                              ),

                              child: Row(
                                children: [
                                  Icon(
                                    Icons
                                        .lock_outline,
                                    size: 18,
                                    color:
                                    colorScheme
                                        .onSurfaceVariant,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child: Text(
                                      'CLAIMED',

                                      style:
                                      theme
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                        color:
                                        colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
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
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    final remaining =
    expiresAt.toDate().difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining == Duration.zero) {
      return Text(
        'Claim expired',
        style: theme
            .textTheme
            .bodySmall
            ?.copyWith(
          fontSize: 12,
          color:
          colorScheme.error,
        ),
      );
    }

    final days =
        remaining.inDays;

    final hours =
        remaining.inHours % 24;

    String text;

    if (days > 0) {
      text =
      'Claim expires in $days day${days == 1 ? '' : 's'}';
    } else {
      text =
      'Claim expires in $hours hour${hours == 1 ? '' : 's'}';
    }

    return Text(
      text,
      style: theme
          .textTheme
          .bodySmall
          ?.copyWith(
        fontSize: 12,
        color:
        colorScheme.tertiary,
        fontWeight:
        FontWeight.w500,
      ),
    );
  }
}