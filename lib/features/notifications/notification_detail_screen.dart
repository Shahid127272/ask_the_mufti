import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_scaffold.dart';
import '../../providers/font_provider.dart';
import '../../services/notification_service.dart';
import 'notification_model.dart';

class NotificationDetailScreen extends StatefulWidget {
  final NotificationModel notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState
    extends State<NotificationDetailScreen> {
  bool _openingAnswer = false;

  @override
  void initState() {
    super.initState();

    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(widget.notification.id)
          .set(
        {'isRead': true},
        SetOptions(merge: true),
      );
    } catch (error) {
      debugPrint(
        'Notification read update failed: $error',
      );
    }
  }

  Future<void> _openAnswer() async {
    final questionId =
    widget.notification.questionId?.trim();

    if (questionId == null || questionId.isEmpty) {
      return;
    }

    if (_openingAnswer) return;

    setState(() {
      _openingAnswer = true;
    });

    try {
      await NotificationService.openAnswerFromNotification(
        questionId,
      );
    } finally {
      if (mounted) {
        setState(() {
          _openingAnswer = false;
        });
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'answer':
        return Icons.question_answer;
      case 'question':
        return Icons.help_outline;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(Timestamp timestamp) {
    final dt = timestamp.toDate();

    final hour =
    dt.hour % 12 == 0 ? 12 : dt.hour % 12;

    final minute =
    dt.minute.toString().padLeft(2, '0');

    final period =
    dt.hour >= 12 ? 'PM' : 'AM';

    final day =
    dt.day.toString().padLeft(2, '0');

    final month =
    dt.month.toString().padLeft(2, '0');

    return '$day/$month/${dt.year} • '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fonts = context.watch<FontProvider>();

    final title =
    widget.notification.title.trim().isEmpty
        ? 'Notification'
        : widget.notification.title.trim();

    final message =
    widget.notification.message.trim().isEmpty
        ? 'No message'
        : widget.notification.message.trim();

    final hasQuestionId =
        widget.notification.questionId != null &&
            widget.notification.questionId!
                .trim()
                .isNotEmpty;

    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // =====================================================
            // NOTIFICATION HEADER
            // =====================================================

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius:
                BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                    colorScheme.primary,
                    child: Icon(
                      _iconForType(
                        widget.notification.type,
                      ),
                      size: 30,
                      color:
                      colorScheme.onPrimary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                      fonts.headingFont,
                      fontSize:
                      fonts.fontSize + 2,
                      fontWeight:
                      FontWeight.bold,
                      fontStyle:
                      fonts.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color:
                      colorScheme.onPrimaryContainer,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatDateTime(
                      widget.notification.time,
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily:
                      fonts.uiFont,
                      fontSize:
                      fonts.fontSize - 2,
                      fontWeight:
                      FontWeight.normal,
                      fontStyle:
                      fonts.isItalic
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // =====================================================
            // MESSAGE
            // =====================================================

            Text(
              'Message',
              style: TextStyle(
                fontFamily: fonts.headingFont,
                fontSize:
                fonts.fontSize + 2,
                fontWeight: FontWeight.bold,
                fontStyle:
                fonts.isItalic
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),

            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius:
                BorderRadius.circular(16),
                border: Border.all(
                  color: theme.dividerColor,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: fonts.uiFont,
                  fontSize: fonts.fontSize,
                  fontWeight: fonts.fontWeight,
                  fontStyle:
                  fonts.isItalic
                      ? FontStyle.italic
                      : FontStyle.normal,
                  height: 1.5,
                ),
              ),
            ),

            // =====================================================
            // OPEN ANSWER
            // =====================================================

            if (hasQuestionId &&
                widget.notification.type ==
                    'answer') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                  _openingAnswer
                      ? null
                      : _openAnswer,
                  icon: _openingAnswer
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.open_in_new,
                  ),
                  label: Text(
                    _openingAnswer
                        ? 'Opening...'
                        : 'Open Answer',
                    style: TextStyle(
                      fontFamily: fonts.uiFont,
                      fontSize:
                      fonts.fontSize,
                      fontWeight:
                      fonts.fontWeight,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}