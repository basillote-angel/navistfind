import 'package:navistfind/features/notifications/domain/enums/notification_type.dart';
import 'package:navistfind/features/notifications/presentation/action_button.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String senderName;
  final String? senderAvatar;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final bool hasMedia;
  final List<ActionButton>? actionButtons;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.senderName,
    this.senderAvatar,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.hasMedia = false,
    this.actionButtons,
  });
}