import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/core/navigation/navigation_service.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';
import 'package:navistfind/features/lost_found/item/application/claim_status_cache_provider.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/features/lost_found/item/presentation/claim_status_page.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/notifications/data/notifications_service.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class PushNotificationListener extends ConsumerStatefulWidget {
  const PushNotificationListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotificationListener> createState() =>
      _PushNotificationListenerState();
}

class _PushNotificationListenerState
    extends ConsumerState<PushNotificationListener> {
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenedSub;

  @override
  void initState() {
    super.initState();
    _initializeListeners();
  }

  Future<void> _initializeListeners() async {
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      await _handleOpenedMessage(initialMessage);
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen((message) async {
      final handled = await _handleNotification(message);
      if (!handled) {
        _showBanner(
          title: message.notification?.title ?? 'New notification',
          body: message.notification?.body ?? 'You have received a new update.',
          color: AppTheme.primaryBlue,
        );
      }
    });

    _onOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
  }

  Future<void> _handleOpenedMessage(RemoteMessage message) async {
    final handled = await _handleNotification(message, forceNavigate: true);
    if (!handled) {
      final navigator = rootNavigator;
      if (navigator != null && navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      }
    }
  }

  /// Main handler for all notification types according to contract
  Future<bool> _handleNotification(
    RemoteMessage message, {
    bool forceNavigate = false,
  }) async {
    final data = message.data;
    if (data.isEmpty) return false;

    // Parse notification type from data payload (contract format)
    final typeString = data['type']?.toString();
    if (typeString == null || typeString.isEmpty) {
      // Fallback to legacy status-based handling
      return await _handleLegacyClaimMessage(
        message,
        forceNavigate: forceNavigate,
      );
    }

    // Parse notification type using NotificationsService parser
    final service = NotificationsService();
    final notificationType = service.parseType(typeString);

    // Get related ID (item ID or claim ID depending on type)
    final relatedId = _parseItemId(data);
    if (relatedId == null) return false;

    // Mark notification as read if notification_id is provided
    final notificationId = data['notification_id']?.toString();
    if (notificationId != null && notificationId.isNotEmpty) {
      try {
        await service.markRead(notificationId);
      } catch (_) {
        // Silently fail - notification marking is not critical
      }
    }

    // Refresh relevant providers
    await _refreshProviders(relatedId);

    if (!mounted) return true;

    // Handle navigation and UI updates based on notification type
    return await _handleNotificationType(
      notificationType,
      relatedId,
      message,
      forceNavigate: forceNavigate,
    );
  }

  /// Handle specific notification types according to contract
  Future<bool> _handleNotificationType(
    NotificationType type,
    int relatedId,
    RemoteMessage message, {
    bool forceNavigate = false,
  }) async {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    final color = _getNotificationColor(type);

    // Show banner for foreground notifications
    if (!forceNavigate) {
      _showBanner(title: title, body: body, color: color);
    }

    // Navigate based on notification type (per contract)
    if (forceNavigate || _shouldAutoNavigate(type)) {
      final navigator = rootNavigator;
      if (navigator == null) return true;

      switch (type) {
        // Student/User notifications
        case NotificationType.claimSubmitted:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ClaimStatusPage(itemId: relatedId),
            ),
          );
          break;

        case NotificationType.claimApproved:
        case NotificationType.collectionReminder:
        case NotificationType.collectionOverdue:
          // Navigate to claim status page showing pickup instructions
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ClaimStatusPage(itemId: relatedId),
            ),
          );
          break;

        case NotificationType.claimRejected:
          // Navigate to rejection details screen
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ClaimStatusPage(itemId: relatedId),
            ),
          );
          break;

        case NotificationType.collectionExpired:
          // Navigate to item details screen (item is reopened)
          showItemDetailsModal(navigator.context, relatedId);
          break;

        case NotificationType.collectionConfirmed:
          // Navigate to success/completion screen
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ClaimStatusPage(itemId: relatedId),
            ),
          );
          break;

        // Admin notifications (if admin app exists)
        case NotificationType.newClaim:
        case NotificationType.multipleClaims:
        case NotificationType.pendingClaimSla:
        case NotificationType.collectionOverdueAdmin:
        case NotificationType.collectionReopened:
        case NotificationType.collectionArchived:
          // For now, navigate to item details
          // In future, could navigate to admin-specific screens
          showItemDetailsModal(navigator.context, relatedId);
          break;

        // Legacy types
        case NotificationType.claimStatusUpdate:
          navigator.push(
            MaterialPageRoute(
              builder: (_) => ClaimStatusPage(itemId: relatedId),
            ),
          );
          break;

        case NotificationType.matchFound:
          showItemDetailsModal(navigator.context, relatedId);
          break;

        default:
          // No navigation for other types
          break;
      }
    }

    // Update claim status cache for claim-related notifications
    if (_isClaimRelated(type)) {
      final cache = ref.read(claimStatusCacheProvider.notifier);
      final claimStatus = _mapNotificationTypeToClaimStatus(type);
      if (claimStatus != null) {
        if (claimStatus == ClaimStatus.withdrawn) {
          cache.clear(relatedId);
        } else {
          cache.setStatus(relatedId, claimStatus);
        }
      }
    }

    return true;
  }

  /// Legacy handler for backward compatibility
  Future<bool> _handleLegacyClaimMessage(
    RemoteMessage message, {
    bool forceNavigate = false,
  }) async {
    final data = message.data;
    final statusString =
        data['status'] ??
        data['claimStatus'] ??
        data['claim_status'] ??
        data['claim_state'];
    final itemId = _parseItemId(data);
    if (statusString == null || itemId == null) return false;

    final claimStatus = _parseClaimStatus(statusString);
    if (claimStatus == null) return false;

    if (!await _isForCurrentUser(data)) return false;

    final cache = ref.read(claimStatusCacheProvider.notifier);
    if (claimStatus == ClaimStatus.withdrawn) {
      cache.clear(itemId);
    } else {
      cache.setStatus(itemId, claimStatus);
    }

    await _refreshProviders(itemId);

    if (!mounted) return true;

    final title = _claimStatusTitle(claimStatus);
    final messageBody = _claimStatusBody(claimStatus);
    final color = _claimStatusColor(claimStatus);
    _showBanner(title: title, body: messageBody, color: color);

    if (forceNavigate ||
        claimStatus == ClaimStatus.approved ||
        claimStatus == ClaimStatus.rejected) {
      final navigator = rootNavigator;
      if (navigator != null) {
        navigator.push(
          MaterialPageRoute(builder: (_) => ClaimStatusPage(itemId: itemId)),
        );
      }
    }
    return true;
  }

  bool _shouldAutoNavigate(NotificationType type) {
    return type == NotificationType.claimApproved ||
        type == NotificationType.claimRejected ||
        type == NotificationType.collectionReminder ||
        type == NotificationType.collectionOverdue ||
        type == NotificationType.collectionExpired ||
        type == NotificationType.collectionConfirmed;
  }

  bool _isClaimRelated(NotificationType type) {
    return type == NotificationType.claimSubmitted ||
        type == NotificationType.claimApproved ||
        type == NotificationType.claimRejected ||
        type == NotificationType.claimStatusUpdate;
  }

  ClaimStatus? _mapNotificationTypeToClaimStatus(NotificationType type) {
    switch (type) {
      case NotificationType.claimSubmitted:
        return ClaimStatus.pending;
      case NotificationType.claimApproved:
        return ClaimStatus.approved;
      case NotificationType.claimRejected:
        return ClaimStatus.rejected;
      default:
        return null;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    // Import colorForNotification from domain
    return colorForNotification(type);
  }

  Future<void> _refreshProviders(int itemId) async {
    ref.invalidate(claimDetailProvider(itemId));
    ref.invalidate(itemDetailsProvider(itemId));
    ref.invalidate(
      itemDetailsWithTypeProvider((id: itemId, type: ItemType.found)),
    );
    ref.invalidate(itemsByTypeProvider(ItemType.found));
    ref.invalidate(itemListProvider);
  }

  Future<bool> _isForCurrentUser(Map<String, dynamic> data) async {
    final claimantIdRaw =
        data['claimantId'] ?? data['claimant_id'] ?? data['user_id'];
    final claimantId = int.tryParse('$claimantIdRaw');
    if (claimantId == null) return true;

    final profileState = ref.read(profileInfoProvider);
    if (profileState.hasValue) {
      final user = profileState.value;
      if (user != null) {
        return user.id == claimantId;
      }
    }
    try {
      final user = await ref.read(profileInfoProvider.future);
      return user.id == claimantId;
    } catch (_) {
      return true;
    }
  }

  void _showBanner({
    required String title,
    required String body,
    required Color color,
  }) {
    final context = rootNavigatorContext;
    if (context == null) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          leading: Icon(Icons.notifications_active, color: color),
          backgroundColor: color.withOpacity(0.12),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.w700, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.darkText),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Dismiss'),
            ),
          ],
        ),
      );
    Future.delayed(const Duration(seconds: 4), () {
      if (rootNavigatorContext != null) {
        messenger.hideCurrentMaterialBanner();
      }
    });
  }

  int? _parseItemId(Map<String, dynamic> data) {
    final raw =
        data['itemId'] ??
        data['item_id'] ??
        data['found_item_id'] ??
        data['relatedId'] ??
        data['related_id'];
    return raw == null ? null : int.tryParse('$raw');
  }

  ClaimStatus? _parseClaimStatus(String raw) {
    final normalized = raw.trim().toUpperCase();
    final cleaned = normalized.startsWith('CLAIM_')
        ? normalized.replaceFirst('CLAIM_', '')
        : normalized;
    switch (cleaned) {
      case 'PENDING':
        return ClaimStatus.pending;
      case 'APPROVED':
        return ClaimStatus.approved;
      case 'REJECTED':
        return ClaimStatus.rejected;
      case 'WITHDRAWN':
      case 'CANCELLED':
      case 'CANCELED':
        return ClaimStatus.withdrawn;
      default:
        return null;
    }
  }

  String _claimStatusTitle(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return 'Claim submitted';
      case ClaimStatus.approved:
        return 'Claim approved';
      case ClaimStatus.rejected:
        return 'Claim rejected';
      case ClaimStatus.withdrawn:
        return 'Claim withdrawn';
    }
  }

  String _claimStatusBody(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return 'We are reviewing your claim. You will receive updates soon.';
      case ClaimStatus.approved:
        return 'Check pickup instructions and prepare your proof of ownership.';
      case ClaimStatus.rejected:
        return 'Review the admin notes and update your evidence before resubmitting.';
      case ClaimStatus.withdrawn:
        return 'Your claim has been cancelled. You can submit a new claim if needed.';
    }
  }

  Color _claimStatusColor(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.pending:
        return AppTheme.warningOrange;
      case ClaimStatus.approved:
        return AppTheme.successGreen;
      case ClaimStatus.rejected:
        return AppTheme.errorRed;
      case ClaimStatus.withdrawn:
        return AppTheme.textGray;
    }
  }

  @override
  void dispose() {
    _onMessageSub?.cancel();
    _onOpenedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
