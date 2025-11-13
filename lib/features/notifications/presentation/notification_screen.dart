import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/notifications/application/notifications_provider.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import '../../../core/theme/app_theme.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  // legacy demo modal removed

  // legacy demo tiles removed

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Failed to load notifications: $e')),
        data: (list) => ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final n = list[i];
            return _NotificationTile(
              notification: n,
              onTap: () {
                // Deep link actions by type
                switch (n.type) {
                  case NotificationType.matchFound:
                    if (n.relatedId != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => ItemDetailsModal(itemId: n.relatedId!),
                      );
                    }
                    break;
                  case NotificationType.adminMessage:
                    // Navigate to Admin Messages thread (placeholder)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Opening admin messages...'),
                      ),
                    );
                    break;
                  case NotificationType.claimStatusUpdate:
                    if (n.relatedId != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => ItemDetailsModal(itemId: n.relatedId!),
                      );
                    }
                    break;
                  case NotificationType.newClaim:
                    if (n.relatedId != null) {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (_) => ItemDetailsModal(itemId: n.relatedId!),
                      );
                    }
                    break;
                  case NotificationType.systemAlert:
                    // No-op or show details
                    break;
                }
                ref.read(notificationsProvider.notifier).markRead(n.id);
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});
  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = iconForNotification(notification.type);
    final color = colorForNotification(notification.type);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
