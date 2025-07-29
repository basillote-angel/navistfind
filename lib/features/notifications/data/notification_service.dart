// Mock Data
import 'package:navistfind/features/notifications/domain/enums/notification_type.dart';
import 'package:navistfind/features/notifications/domain/models/notification_item.dart';
import 'package:navistfind/features/notifications/presentation/action_button.dart';

final List<NotificationItem> mockNotifications = [
  NotificationItem(
    id: '1',
    title: 'Potential Match Found!',
    message: 'Someone found a green Backpack that matches your lost item description. Tap to see details.',
    senderName: 'FinderSystem',
    senderAvatar: null,
    type: NotificationType.itemMatched,
    timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    isRead: false,
    hasMedia: true,
    actionButtons: [
      const ActionButton(label: 'View Match', isPrimary: true),
      const ActionButton(label: 'Not Mine'),
    ],
  ),
  NotificationItem(
    id: '2',
    title: 'New Message',
    message: 'Sarah: "I found your wallet. When can we arrange a meetup for the return?"',
    senderName: 'Sarah Johnson',
    senderAvatar: null,
    type: NotificationType.message,
    timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    isRead: false,
    actionButtons: [
      const ActionButton(label: 'Reply', isPrimary: true),
    ],
  ),
  NotificationItem(
    id: '4',
    title: 'Item Successfully Claimed',
    message: 'Your Gold Ring has been successfully returned! Please rate your experience.',
    senderName: 'ClaimSystem',
    senderAvatar: null,
    type: NotificationType.itemClaimed,
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: true,
    actionButtons: [
      const ActionButton(label: 'Rate Experience', isPrimary: true),
      const ActionButton(label: 'Later'),
    ],
  ),
  NotificationItem(
    id: '6',
    title: 'New Item Found',
    message: 'A Red Bicycle has been reported found near your last reported location. Is it yours?',
    senderName: 'FinderSystem',
    senderAvatar: null,
    type: NotificationType.itemFound,
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
    hasMedia: true,
    actionButtons: [
      const ActionButton(label: 'Yes, Mine', isPrimary: true),
      const ActionButton(label: 'Not Mine'),
    ],
  ),
];
