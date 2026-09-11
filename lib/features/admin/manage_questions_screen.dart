import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/role_view_controller.dart';
import '../../models/question_model.dart';
import '../../services/questions_firestore_service.dart';

class ManageQuestionsScreen extends StatefulWidget {
  const ManageQuestionsScreen({super.key});

  @override
  State<ManageQuestionsScreen> createState() =>
      _ManageQuestionsScreenState();
}

class _ManageQuestionsScreenState
    extends State<ManageQuestionsScreen> {
  final QuestionsFirestoreService _service =
  QuestionsFirestoreService();

  final TextEditingController _searchController =
  TextEditingController();

  String _selectedStatus = 'all';
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================
  // QUERY
  // =========================================================

  Query<Map<String, dynamic>> _questionsQuery() {
    return FirebaseFirestore.instance
        .collection('questions')
        .orderBy('updatedAt', descending: true);
  }

  // =========================================================
  // EDIT QUESTION DIALOG
  // =========================================================

  Future<void> _editQuestion(
      QuestionModel question,
      ) async {
    final controller = TextEditingController(
      text: question.questionText,
    );
    final realRole =
        context.read<RoleViewController>().realRole;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Question'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 6,
            minLines: 3,
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'Sawal likhiye',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = controller.text.trim();

                if (text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sawal khali nahi ho sakta',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  text,
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (result == null) {
      return;
    }

    if (result == question.questionText.trim()) {
      return;
    }
    try {
      await _service.editQuestionByAdminOrOwner(
        questionId: question.id,
        newQuestionText: result,
        editorRole: realRole,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sawal update ho gaya',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sawal update nahi ho saka',
          ),
        ),
      );

      debugPrint('Edit question error: $e');
    }
  }

  // =========================================================
  // DELETE QUESTION
  // =========================================================

  Future<void> _deleteQuestion(
      QuestionModel question,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Question'),
          content: const Text(
            'Kya aap is sawal ko delete karna chahte hain?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _service.deleteQuestion(
        question.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sawal delete ho gaya',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sawal delete nahi ho saka',
          ),
        ),
      );

      debugPrint('Delete question error: $e');
    }
  }

  // =========================================================
  // STATUS LABEL
  // =========================================================

  String _statusLabel(String status) {
    switch (status) {
      case 'new':
        return 'NEW';

      case 'pending':
        return 'PENDING';

      case 'published':
        return 'PUBLISHED';

      default:
        return status.toUpperCase();
    }
  }

  // =========================================================
  // STATUS ICON
  // =========================================================

  IconData _statusIcon(String status) {
    switch (status) {
      case 'new':
        return Icons.fiber_new;

      case 'pending':
        return Icons.pending_actions;

      case 'published':
        return Icons.check_circle;

      default:
        return Icons.help_outline;
    }
  }

  // =========================================================
  // FILTER QUESTIONS
  // =========================================================

  List<QuestionModel> _filterQuestions(
      List<QuestionModel> questions,
      ) {
    return questions.where((question) {
      final matchesStatus =
          _selectedStatus == 'all' ||
              question.status == _selectedStatus;

      final query = _searchText.trim().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
              question.questionText
                  .toLowerCase()
                  .contains(query) ||
              question.askedBy
                  .toLowerCase()
                  .contains(query);

      return matchesStatus && matchesSearch;
    }).toList();
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final roleController =
    context.watch<RoleViewController>();

    final realRole =
        roleController.realRole;

    final hasAccess =
        realRole == 'owner' ||
            realRole == 'admin';

    if (!hasAccess) {
      return AppScaffold(
        notificationCount: 0,
        body: Center(
          child: Text(
            'Access denied\n(Admin / Owner only)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      );
    }

    return AppScaffold(
      notificationCount: 0,
      body: Column(
        children: [
          // =================================================
          // HEADER
          // =================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              12,
            ),
            color: theme.colorScheme.primary,
            child: Text(
              'Manage Questions',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // =================================================
          // SEARCH
          // =================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              12,
              12,
              6,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(
                  Icons.search,
                ),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchText = '';
                    });
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),

          // =================================================
          // STATUS FILTER
          // =================================================

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected:
                  _selectedStatus == 'all',
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = 'all';
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('New'),
                  selected:
                  _selectedStatus == 'new',
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = 'new';
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Pending'),
                  selected:
                  _selectedStatus == 'pending',
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = 'pending';
                    });
                  },
                ),

                const SizedBox(width: 8),

                ChoiceChip(
                  label: const Text('Published'),
                  selected:
                  _selectedStatus == 'published',
                  onSelected: (_) {
                    setState(() {
                      _selectedStatus = 'published';
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // =================================================
          // QUESTIONS LIST
          // =================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _questionsQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                    'Manage questions error: '
                        '${snapshot.error}',
                  );

                  return const Center(
                    child: Text(
                      'Questions load nahi ho sake',
                    ),
                  );
                }

                final allQuestions =
                    snapshot.data?.docs
                        .map(
                          (doc) =>
                          QuestionModel
                              .fromFirestore(
                            doc,
                          ),
                    )
                        .toList() ??
                        <QuestionModel>[];

                final questions =
                _filterQuestions(allQuestions);

                if (questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'Koi sawal nahi mila',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: questions.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final question =
                    questions[index];

                    return Card(
                      child: Padding(
                        padding:
                        const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            // STATUS

                            Row(
                              children: [
                                Icon(
                                  _statusIcon(
                                    question.status,
                                  ),
                                  size: 18,
                                  color: theme
                                      .colorScheme
                                      .primary,
                                ),

                                const SizedBox(width: 6),

                                Text(
                                  _statusLabel(
                                    question.status,
                                  ),
                                  style: theme
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                    color: theme
                                        .colorScheme
                                        .primary,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),

                                const Spacer(),

                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value ==
                                        'edit') {
                                      _editQuestion(
                                        question,
                                      );
                                    }

                                    if (value ==
                                        'delete') {
                                      _deleteQuestion(
                                        question,
                                      );
                                    }
                                  },
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            'Edit',
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                          ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            'Delete',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // QUESTION

                            Text(
                              question.questionText,
                              style: theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ASKED BY

                            Text(
                              'Asked by: '
                                  '${question.askedBy}',
                              style:
                              theme.textTheme.bodySmall,
                            ),

                            const SizedBox(height: 12),

                            // BUTTONS

                            Row(
                              children: [
                                Expanded(
                                  child:
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      _editQuestion(
                                        question,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.edit,
                                    ),
                                    label: const Text(
                                      'Edit Question',
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 8),

                                IconButton(
                                  tooltip:
                                  'Delete Question',
                                  onPressed: () {
                                    _deleteQuestion(
                                      question,
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                ),
                              ],
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
    );
  }
}