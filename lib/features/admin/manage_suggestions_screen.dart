import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../core/constants.dart';
import '../../core/role_view_controller.dart';

class ManageSuggestionsScreen extends StatefulWidget {
  const ManageSuggestionsScreen({super.key});

  @override
  State<ManageSuggestionsScreen> createState() =>
      _ManageSuggestionsScreenState();
}

class _ManageSuggestionsScreenState
    extends State<ManageSuggestionsScreen> {
  final FirebaseFirestore _db =
      FirebaseFirestore.instance;

  String _selectedStatus = 'all';

  // ============================================================
  // UPDATE STATUS
  // ============================================================

  Future<void> _updateStatus(
      String suggestionId,
      String status,
      ) async {
    try {
      await _db
          .collection(AppConstants.suggestionsCollection)
          .doc(suggestionId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Suggestion status update ho gaya.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'UPDATE SUGGESTION STATUS ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Status update nahi ho saka.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE SUGGESTION
  // ============================================================

  Future<void> _deleteSuggestion(
      String suggestionId,
      ) async {
    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Suggestion?',
          ),
          content: const Text(
            'Kya aap is suggestion ko permanently delete karna chahte hain?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _db
          .collection(
        AppConstants.suggestionsCollection,
      )
          .doc(suggestionId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Suggestion delete ho gayi.',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'DELETE SUGGESTION ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Suggestion delete nahi ho saki.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String _statusText(String status) {
    switch (status) {
      case 'new':
        return 'New';

      case 'inReview':
        return 'In Review';

      case 'resolved':
        return 'Resolved';

      default:
        return status;
    }
  }

  // ============================================================
  // STATUS COLOR
  // ============================================================

  Color _statusColor(
      BuildContext context,
      String status,
      ) {
    final theme = Theme.of(context);

    switch (status) {
      case 'new':
        return theme.colorScheme.primary;

      case 'inReview':
        return Colors.orange;

      case 'resolved':
        return Colors.green;

      default:
        return theme.colorScheme.outline;
    }
  }

  // ============================================================
  // STATUS FILTER
  // ============================================================

  Widget _statusFilter() {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'All',
            value: 'all',
            theme: theme,
          ),
          _filterChip(
            label: 'New',
            value: 'new',
            theme: theme,
          ),
          _filterChip(
            label: 'In Review',
            value: 'inReview',
            theme: theme,
          ),
          _filterChip(
            label: 'Resolved',
            value: 'resolved',
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        right: 8,
      ),
      child: ChoiceChip(
        label: Text(label),
        selected: _selectedStatus == value,
        onSelected: (_) {
          setState(() {
            _selectedStatus = value;
          });
        },
      ),
    );
  }

  // ============================================================
  // SUGGESTION CARD
  // ============================================================

  Widget _suggestionCard(
      BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final theme = Theme.of(context);
    final data = doc.data();

    final userName =
        data['userName']?.toString() ?? 'User';

    final suggestion =
        data['suggestion']?.toString() ?? '';

    final status =
        data['status']?.toString() ?? 'new';

    final createdAt =
    data['createdAt'] as Timestamp?;

    final dateText =
    createdAt != null
        ? _formatDate(createdAt)
        : 'Date unavailable';

    final statusColor =
    _statusColor(context, status);

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // ==================================================
            // USER + STATUS
            // ==================================================

            Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  child: Text(
                    userName.isNotEmpty
                        ? userName[0]
                        .toUpperCase()
                        : 'U',
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
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

                      const SizedBox(height: 4),

                      Text(
                        dateText,
                        style: theme
                            .textTheme
                            .bodySmall,
                      ),
                    ],
                  ),
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // SUGGESTION
            // ==================================================

            Text(
              suggestion,
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // ==================================================
            // ACTIONS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showStatusMenu(
                        context,
                        doc.id,
                        status,
                      );
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                    ),
                    label: const Text(
                      'Status',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                IconButton(
                  tooltip: 'Delete',
                  onPressed: () {
                    _deleteSuggestion(
                      doc.id,
                    );
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STATUS MENU
  // ============================================================

  void _showStatusMenu(
      BuildContext context,
      String suggestionId,
      String currentStatus,
      ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Update Suggestion Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.fiber_new,
                ),
                title: const Text('New'),
                trailing:
                currentStatus == 'new'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.pop(context);

                  _updateStatus(
                    suggestionId,
                    'new',
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.rate_review_outlined,
                ),
                title: const Text('In Review'),
                trailing:
                currentStatus == 'inReview'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.pop(context);

                  _updateStatus(
                    suggestionId,
                    'inReview',
                  );
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                ),
                title: const Text('Resolved'),
                trailing:
                currentStatus == 'resolved'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  Navigator.pop(context);

                  _updateStatus(
                    suggestionId,
                    'resolved',
                  );
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatDate(
      Timestamp timestamp,
      ) {
    final date = timestamp.toDate();

    final day =
    date.day.toString().padLeft(2, '0');

    final month =
    date.month.toString().padLeft(2, '0');

    final year =
    date.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final role =
        context.watch<RoleViewController>()
            .activeRole;

    // ==========================================================
    // ACCESS CHECK
    // ==========================================================

    if (role != 'admin' &&
        role != 'owner') {
      return AppScaffold(
        body: Center(
          child: Text(
            'Access denied\n(Admin / Owner only)',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium,
          ),
        ),
      );
    }

    return AppScaffold(
      body: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================

          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'Manage Suggestions',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Text(
              'Users ki private suggestions yahan sirf Admin aur Owner ko dikhengi.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium,
            ),
          ),

          const SizedBox(height: 16),

          // ====================================================
          // FILTER
          // ====================================================

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: _statusFilter(),
          ),

          const SizedBox(height: 8),

          const Divider(),

          // ====================================================
          // LIST
          // ====================================================

          Expanded(
            child: StreamBuilder<
                QuerySnapshot<Map<String, dynamic>>>(
              stream: _db
                  .collection(
                AppConstants
                    .suggestionsCollection,
              )
                  .orderBy(
                'createdAt',
                descending: true,
              )
                  .snapshots(),
              builder: (
                  context,
                  snapshot,
                  ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(24),
                      child: Text(
                        'Suggestions load nahi ho saki.\n\n'
                            '${snapshot.error}',
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ?? [];

                final filteredDocs =
                _selectedStatus == 'all'
                    ? docs
                    : docs.where(
                      (doc) {
                    final status =
                    doc.data()['status']
                        ?.toString();

                    return status ==
                        _selectedStatus;
                  },
                ).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 60,
                            color: Theme.of(context)
                                .colorScheme
                                .outline,
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          Text(
                            _selectedStatus ==
                                'all'
                                ? 'Abhi koi suggestion nahi hai.'
                                : 'Is status ki koi suggestion nahi hai.',
                            textAlign:
                            TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium,
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
                  filteredDocs.length,
                  itemBuilder: (
                      context,
                      index,
                      ) {
                    return _suggestionCard(
                      context,
                      filteredDocs[index],
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