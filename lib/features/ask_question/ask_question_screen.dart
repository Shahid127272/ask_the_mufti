import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/font_provider.dart';
import '../../core/app_scaffold.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';
import '../answer_detail/answer_detail_screen.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() =>
      _AskQuestionScreenState();
}

class _AskQuestionScreenState
    extends State<AskQuestionScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  final _titleController =
  TextEditingController();

  final _questionController =
  TextEditingController();

  bool _loading = false;

  bool _hideMyName = false;

  List<DocumentSnapshot<Map<String, dynamic>>>
  _similarQuestions = [];

  // =========================================================
  // 🔍 SEARCH SIMILAR QUESTIONS
  // =========================================================

  Future<void> _searchSimilar(
      String text,
      ) async {
    final searchText = text.trim();

    if (searchText.length < 5) {
      if (mounted) {
        setState(() {
          _similarQuestions = [];
        });
      }

      return;
    }

    try {
      final query = await FirebaseFirestore
          .instance
          .collection('questions')
          .where(
        'status',
        isEqualTo: 'published',
      )
          .limit(20)
          .get();

      if (!mounted) return;

      final searchLower =
      searchText.toLowerCase();

      final results = query.docs.where((doc) {
        final data = doc.data();

        final questionText =
            data['questionText']
                ?.toString()
                .toLowerCase() ??
                '';

        return questionText.contains(
          searchLower,
        );
      }).take(5).toList();

      setState(() {
        _similarQuestions = results;
      });
    } catch (e) {
      debugPrint(
        'Similar question search error: $e',
      );
    }
  }

  // =========================================================
  // ➕ SUBMIT QUESTION
  // =========================================================

  Future<void> _submitQuestion() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text('Please login first'),
        ),
      );

      return;
    }

    final title =
    _titleController.text.trim();

    final details =
    _questionController.text.trim();

    if (title.isEmpty ||
        details.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please write your question',
          ),
        ),
      );

      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final userName =
      user.displayName
          ?.trim()
          .isNotEmpty ==
          true
          ? user.displayName!.trim()
          : 'User';

      // Title + details ko ek hi questionText
      // mein save kiya jayega.
      final questionText =
          '$title\n\n$details';

      await _service.addQuestion(
        questionText: questionText,
        userId: user.uid,
        askedBy: userName,
        hideAskedByName: _hideMyName,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Question submitted successfully',
          ),
        ),
      );

      _titleController.clear();
      _questionController.clear();

      setState(() {
        _similarQuestions = [];
        _hideMyName = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // =========================================================
  // 🧹 DISPOSE
  // =========================================================

  @override
  void dispose() {
    _titleController.dispose();
    _questionController.dispose();

    super.dispose();
  }

  // =========================================================
  // 🎨 BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final fonts =
    context.watch<FontProvider>();

    return AppScaffold(
      body: SingleChildScrollView(
        padding:
        const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =================================================
            // TITLE
            // =================================================

            TextField(
              controller:
              _titleController,
              textInputAction:
              TextInputAction.next,
              decoration:
              InputDecoration(
                labelText:
                'Question Title',
                labelStyle:
                TextStyle(
                  fontFamily:
                  fonts.uiFont,
                ),
              ),
              style:
              TextStyle(
                fontFamily:
                fonts.questionFont,
              ),
              onChanged:
              _searchSimilar,
            ),

            // =================================================
            // SIMILAR QUESTIONS
            // =================================================

            if (_similarQuestions
                .isNotEmpty) ...[
              const SizedBox(height: 12),

              Text(
                'Similar questions already answered:',
                style: TextStyle(
                  fontFamily:
                  fonts.headingFont,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              ..._similarQuestions.map(
                    (doc) {
                  final data =
                  doc.data();

                  final questionText =
                      data?['questionText']
                          ?.toString() ??
                          '';

                  return Card(
                    child: ListTile(
                      title: Text(
                        questionText,
                        maxLines: 2,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style: TextStyle(
                          fontFamily:
                          fonts.headingFont,
                        ),
                      ),
                      trailing:
                      const Icon(
                        Icons
                            .arrow_forward,
                      ),
                      onTap: () {
                        final question =
                        QuestionModel
                            .fromFirestore(
                          doc,
                        );

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
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 16),

            // =================================================
            // QUESTION DETAILS
            // =================================================

            TextField(
              controller:
              _questionController,
              maxLines: 7,
              textInputAction:
              TextInputAction.newline,
              decoration:
              InputDecoration(
                labelText:
                'Question Details',
                alignLabelWithHint: true,
                labelStyle:
                TextStyle(
                  fontFamily:
                  fonts.uiFont,
                ),
              ),
              style:
              TextStyle(
                fontFamily:
                fonts.questionFont,
              ),
            ),

            const SizedBox(height: 20),

            // =================================================
            // HIDE MY NAME
            // =================================================

            CheckboxListTile(
              contentPadding:
              EdgeInsets.zero,
              value:
              _hideMyName,
              onChanged:
              _loading
                  ? null
                  : (value) {
                setState(() {
                  _hideMyName =
                      value ?? false;
                });
              },
              title:
              const Text(
                'Hide my name',
              ),
              subtitle:
              const Text(
                'Your name will be shown as Anonymous.',
              ),
              controlAffinity:
              ListTileControlAffinity
                  .leading,
            ),

            const SizedBox(height: 12),

            // =================================================
            // SUBMIT
            // =================================================

            SizedBox(
              width:
              double.infinity,
              child:
              ElevatedButton(
                onPressed:
                _loading
                    ? null
                    : _submitQuestion,
                child: _loading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child:
                  CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Submit Question',
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}