import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/app_scaffold.dart';
import '../../services/notification_service.dart';
import 'notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      notificationCount: 0,
      body: userId == null
          ? Center(
        child: Text(
          'User not logged in',
          style: theme.textTheme.bodyMedium,
        ),
      )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load notifications',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No notifications',
                style: theme.textTheme.bodyLarge,
              ),
            );
          }

          final notifications = snapshot.data!.docs
              .map(NotificationModel.fromFirestore)
              .toList()
            ..sort(
                  (a, b) => b.time.compareTo(a.time),
            );

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 12,
            ),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];

              return Dismissible(
                key: Key(notif.id),
                direction:
                DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.delete,
                    color: colorScheme.onError,
                  ),
                ),
                onDismissed: (_) async {
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(notif.id)
                      .delete();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text('Deleted'),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: notif.isRead ? 1 : 5,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: notif.isRead
                          ? colorScheme
                          .surfaceContainerHighest
                          : colorScheme.primary,
                      child: Icon(
                        _iconForType(notif.type),
                        color: notif.isRead
                            ? colorScheme
                            .onSurfaceVariant
                            : colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      notif.title.isEmpty
                          ? 'Notification'
                          : notif.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(
                        fontWeight: notif.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      notif.message.isEmpty
                          ? 'No message'
                          : notif.message,
                      style:
                      theme.textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      _formatTime(notif.time),
                      style: theme.textTheme.bodySmall,
                    ),
                    onTap: () async {
                      await NotificationService
                          .handleNotificationTap(
                        notif,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
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

  String _formatTime(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final hour =
    dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute =
    dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}