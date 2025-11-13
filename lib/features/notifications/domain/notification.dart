import 'package:flutter/material.dart';

enum NotificationType {
  matchFound,
  adminMessage,
  claimStatusUpdate,
  systemAlert,
  newClaim, // For admin notifications about new claims
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.relatedId,
    this.score,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final int? relatedId; // itemId, claimId, threadId depending on type
  final double? score; // for matchFound

  bool get isRead => readAt != null;
}

IconData iconForNotification(NotificationType type) {
  switch (type) {
    case NotificationType.matchFound:
      return Icons.auto_awesome;
    case NotificationType.adminMessage:
      return Icons.chat_bubble_outline;
    case NotificationType.claimStatusUpdate:
      return Icons.assignment_turned_in;
    case NotificationType.newClaim:
      return Icons.add_alert;
    case NotificationType.systemAlert:
      return Icons.campaign_outlined;
  }
}

Color colorForNotification(NotificationType type) {
  switch (type) {
    case NotificationType.matchFound:
      return const Color(0xFF1C2A40);
    case NotificationType.adminMessage:
      return const Color(0xFF1C2A40);
    case NotificationType.claimStatusUpdate:
      return const Color(0xFF2E7D32);
    case NotificationType.newClaim:
      return const Color(0xFF1976D2);
    case NotificationType.systemAlert:
      return const Color(0xFFC62828);
  }
}
