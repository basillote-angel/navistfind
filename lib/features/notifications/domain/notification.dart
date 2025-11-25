import 'package:flutter/material.dart';

enum NotificationType {
  matchFound,
  adminMessage,
  claimStatusUpdate,
  systemAlert,
  newClaim, // For admin notifications about new claims
  // Student/User notification types from contract
  claimSubmitted,
  claimApproved,
  claimRejected,
  collectionReminder,
  collectionOverdue,
  collectionExpired,
  collectionConfirmed,

  // Admin notification types from contract
  multipleClaims,
  pendingClaimSla,
  collectionOverdueAdmin,
  collectionReopened,
  collectionArchived,
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
    required this.rawType,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final int? relatedId; // itemId, claimId, threadId depending on type
  final double? score; // for matchFound
  final String rawType;

  bool get isRead => readAt != null;

  bool get isClaimStatus =>
      type == NotificationType.claimStatusUpdate ||
      type == NotificationType.claimSubmitted ||
      type == NotificationType.claimApproved ||
      type == NotificationType.claimRejected;

  bool get isClaimApproved {
    if (type == NotificationType.claimApproved) return true;
    if (!isClaimStatus) return false;
    final normalized = rawType.toLowerCase();
    if (normalized.contains('approved')) return true;
    if (normalized.contains('rejected')) return false;
    return title.toLowerCase().contains('approved');
  }

  bool get isCollectionRelated =>
      type == NotificationType.collectionReminder ||
      type == NotificationType.collectionOverdue ||
      type == NotificationType.collectionExpired ||
      type == NotificationType.collectionConfirmed;

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      relatedId: relatedId,
      score: score,
      rawType: rawType,
    );
  }
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
    case NotificationType.claimSubmitted:
      return Icons.send_outlined;
    case NotificationType.claimApproved:
      return Icons.check_circle_outline;
    case NotificationType.claimRejected:
      return Icons.cancel_outlined;
    case NotificationType.collectionReminder:
      return Icons.notifications_active_outlined;
    case NotificationType.collectionOverdue:
      return Icons.warning_amber_rounded;
    case NotificationType.collectionExpired:
      return Icons.schedule_outlined;
    case NotificationType.collectionConfirmed:
      return Icons.verified_outlined;
    case NotificationType.multipleClaims:
      return Icons.people_outline;
    case NotificationType.pendingClaimSla:
      return Icons.access_time_outlined;
    case NotificationType.collectionOverdueAdmin:
      return Icons.warning_outlined;
    case NotificationType.collectionReopened:
      return Icons.refresh_outlined;
    case NotificationType.collectionArchived:
      return Icons.archive_outlined;
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
    case NotificationType.claimSubmitted:
      return const Color(0xFFF57C00); // Orange
    case NotificationType.claimApproved:
      return const Color(0xFF2E7D32); // Green
    case NotificationType.claimRejected:
      return const Color(0xFFC62828); // Red
    case NotificationType.collectionReminder:
      return const Color(0xFF1976D2); // Blue
    case NotificationType.collectionOverdue:
      return const Color(0xFFF57C00); // Orange/Warning
    case NotificationType.collectionExpired:
      return const Color(0xFF757575); // Gray
    case NotificationType.collectionConfirmed:
      return const Color(0xFF2E7D32); // Green
    case NotificationType.multipleClaims:
      return const Color(0xFF1976D2); // Blue
    case NotificationType.pendingClaimSla:
      return const Color(0xFFF57C00); // Orange
    case NotificationType.collectionOverdueAdmin:
      return const Color(0xFFC62828); // Red
    case NotificationType.collectionReopened:
      return const Color(0xFF1976D2); // Blue
    case NotificationType.collectionArchived:
      return const Color(0xFF757575); // Gray
  }
}
