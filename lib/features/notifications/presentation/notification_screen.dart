import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navistfind/features/notifications/application/notifications_provider.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';
import 'package:navistfind/features/notifications/presentation/notification_modals.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import '../../../core/theme/app_theme.dart';

enum NotificationFilter { all, unread, claims, matches, collections }

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  NotificationFilter _currentFilter = NotificationFilter.all;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
  ) {
    switch (_currentFilter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.claims:
        return notifications
            .where(
              (n) =>
                  n.type == NotificationType.claimSubmitted ||
                  n.type == NotificationType.claimApproved ||
                  n.type == NotificationType.claimRejected ||
                  n.type == NotificationType.claimStatusUpdate,
            )
            .toList();
      case NotificationFilter.matches:
        return notifications
            .where((n) => n.type == NotificationType.matchFound)
            .toList();
      case NotificationFilter.collections:
        return notifications
            .where(
              (n) =>
                  n.type == NotificationType.collectionReminder ||
                  n.type == NotificationType.collectionOverdue ||
                  n.type == NotificationType.collectionExpired ||
                  n.type == NotificationType.collectionConfirmed,
            )
            .toList();
    }
  }

  Map<String, List<AppNotification>> _groupNotifications(
    List<AppNotification> notifications,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    final Map<String, List<AppNotification>> grouped = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Older': [],
    };

    for (final notification in notifications) {
      final notificationDate = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );
      if (notificationDate == today) {
        grouped['Today']!.add(notification);
      } else if (notificationDate == yesterday) {
        grouped['Yesterday']!.add(notification);
      } else if (notificationDate.isAfter(weekAgo)) {
        grouped['This Week']!.add(notification);
      } else {
        grouped['Older']!.add(notification);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    Future<void> handleNotificationTap(AppNotification notification) async {
      switch (notification.type) {
        // Legacy types
        case NotificationType.matchFound:
          if (notification.relatedId != null) {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => ItemDetailsModal(itemId: notification.relatedId!),
            );
          }
          break;
        case NotificationType.adminMessage:
          await showSimpleNotificationModal(context, notification);
          break;
        // Claim submitted - show modal with cancel option
        case NotificationType.claimSubmitted:
          await showClaimSubmittedModal(context, ref, notification);
          break;
        // Claim approved - show approval modal
        case NotificationType.claimApproved:
          await showClaimApprovalModal(context, notification);
          break;
        // Claim rejected - show rejection modal
        case NotificationType.claimRejected:
          await showClaimRejectionModal(context, notification);
          break;
        // Collection reminders - show reminder modal
        case NotificationType.collectionReminder:
        case NotificationType.collectionOverdue:
          await showCollectionReminderModal(context, notification);
          break;
        // Collection confirmed - show simple modal
        case NotificationType.collectionConfirmed:
          await showSimpleNotificationModal(context, notification);
          break;
        case NotificationType.claimStatusUpdate:
          // Fallback to simple modal for legacy status updates
          await showSimpleNotificationModal(context, notification);
          break;
        case NotificationType.collectionExpired:
          // Navigate to item details (item is reopened)
          if (notification.relatedId != null) {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => ItemDetailsModal(itemId: notification.relatedId!),
            );
          }
          break;
        // Admin notification types
        case NotificationType.newClaim:
        case NotificationType.multipleClaims:
        case NotificationType.pendingClaimSla:
        case NotificationType.collectionOverdueAdmin:
        case NotificationType.collectionReopened:
        case NotificationType.collectionArchived:
          if (notification.relatedId != null) {
            await showDialog(
              context: context,
              barrierDismissible: true,
              builder: (_) => ItemDetailsModal(itemId: notification.relatedId!),
            );
          }
          break;
        case NotificationType.systemAlert:
          await showSimpleNotificationModal(context, notification);
          break;
      }
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final horizontalPadding = isTablet ? screenWidth * 0.15 : 0.0;

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? AppTheme.spacingXL : 20,
                ),
                child: _buildModernAppBar(notificationsAsync, isTablet),
              ),
            ],
          ),
        ),
      ),
      body: Container(
        color: AppTheme.lightGray,
        child: Column(
          children: [
            _buildFilterChips(notificationsAsync, isTablet),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref.read(notificationsProvider.notifier).load();
                },
                color: AppTheme.primaryBlue,
                backgroundColor: Colors.white,
                strokeWidth: 3.0,
                displacement: 40.0,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: notificationsAsync.when(
                    loading: () => _buildShimmerLoading(isTablet),
                    error: (e, _) => _buildErrorState(e),
                    data: (list) {
                      final filtered = _filterNotifications(list);
                      if (filtered.isEmpty) {
                        return _buildEmptyState();
                      }
                      final grouped = _groupNotifications(filtered);
                      return _buildGroupedNotificationList(
                        grouped,
                        handleNotificationTap,
                        isTablet,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar(
    AsyncValue<List<AppNotification>> notificationsAsync,
    bool isTablet,
  ) {
    final unreadCount = notificationsAsync.maybeWhen(
      data: (list) => list.where((n) => !n.isRead).length,
      orElse: () => 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXLarge),
          bottomRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingL,
        vertical: AppTheme.spacingM,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            child: Row(
              children: [
                const Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(
    AsyncValue<List<AppNotification>> notificationsAsync,
    bool isTablet,
  ) {
    return Container(
      height: isTablet ? 70 : 60,
      padding: EdgeInsets.symmetric(
        vertical: AppTheme.spacingS,
        horizontal: isTablet ? AppTheme.spacingXL : 0,
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _currentFilter == NotificationFilter.all,
            count: notificationsAsync.maybeWhen(
              data: (list) => list.length,
              orElse: () => 0,
            ),
            onTap: () {
              setState(() => _currentFilter = NotificationFilter.all);
            },
          ),
          const SizedBox(width: AppTheme.spacingS),
          _FilterChip(
            label: 'Unread',
            isSelected: _currentFilter == NotificationFilter.unread,
            count: notificationsAsync.maybeWhen(
              data: (list) => list.where((n) => !n.isRead).length,
              orElse: () => 0,
            ),
            onTap: () {
              setState(() => _currentFilter = NotificationFilter.unread);
            },
          ),
          const SizedBox(width: AppTheme.spacingS),
          _FilterChip(
            label: 'Claims',
            isSelected: _currentFilter == NotificationFilter.claims,
            count: notificationsAsync.maybeWhen(
              data: (list) => list
                  .where(
                    (n) =>
                        n.type == NotificationType.claimSubmitted ||
                        n.type == NotificationType.claimApproved ||
                        n.type == NotificationType.claimRejected ||
                        n.type == NotificationType.claimStatusUpdate,
                  )
                  .length,
              orElse: () => 0,
            ),
            onTap: () {
              setState(() => _currentFilter = NotificationFilter.claims);
            },
          ),
          const SizedBox(width: AppTheme.spacingS),
          _FilterChip(
            label: 'Matches',
            isSelected: _currentFilter == NotificationFilter.matches,
            count: notificationsAsync.maybeWhen(
              data: (list) => list
                  .where((n) => n.type == NotificationType.matchFound)
                  .length,
              orElse: () => 0,
            ),
            onTap: () {
              setState(() => _currentFilter = NotificationFilter.matches);
            },
          ),
          const SizedBox(width: AppTheme.spacingS),
          _FilterChip(
            label: 'Collections',
            isSelected: _currentFilter == NotificationFilter.collections,
            count: notificationsAsync.maybeWhen(
              data: (list) => list
                  .where(
                    (n) =>
                        n.type == NotificationType.collectionReminder ||
                        n.type == NotificationType.collectionOverdue ||
                        n.type == NotificationType.collectionExpired ||
                        n.type == NotificationType.collectionConfirmed,
                  )
                  .length,
              orElse: () => 0,
            ),
            onTap: () {
              setState(() => _currentFilter = NotificationFilter.collections);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading(bool isTablet) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingL,
      ),
      itemCount: 5,
      itemBuilder: (context, index) =>
          _NotificationShimmerTile(index: index, isTablet: isTablet),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorRed.withOpacity(0.5),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'Failed to load notifications',
              style: AppTheme.heading3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              error.toString(),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(notificationsProvider.notifier).load();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: AppTheme.getPrimaryButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 64,
                color: AppTheme.primaryBlue.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No Notifications',
              style: AppTheme.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              _currentFilter == NotificationFilter.unread
                  ? 'You\'re all caught up! No unread notifications.'
                  : 'You don\'t have any notifications yet.',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGray),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedNotificationList(
    Map<String, List<AppNotification>> grouped,
    Future<void> Function(AppNotification) onTap,
    bool isTablet,
  ) {
    final List<Widget> widgets = [];
    int globalIndex = 0;

    grouped.forEach((groupTitle, notifications) {
      widgets.add(
        _NotificationGroupHeader(
          title: groupTitle,
          count: notifications.length,
          isTablet: isTablet,
        ),
      );

      for (final notification in notifications) {
        widgets.add(
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (globalIndex * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _ModernNotificationTile(
              notification: notification,
              isTablet: isTablet,
              onTap: () async {
                print(
                  '[NotificationScreen] Tapped notification: ${notification.id}, type: ${notification.type}',
                );
                try {
                  await onTap(notification);
                  print('[NotificationScreen] Modal closed, marking as read');
                  await ref
                      .read(notificationsProvider.notifier)
                      .markRead(notification.id);
                } catch (e, stackTrace) {
                  print('[NotificationScreen] Error showing modal: $e');
                  print('[NotificationScreen] Stack trace: $stackTrace');
                  if (context.mounted) {
                    await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Failed to show notification: $e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
        globalIndex++;
      }
    });

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        top: AppTheme.spacingM,
        bottom: AppTheme.spacingXXL,
        left: isTablet ? AppTheme.spacingXL : 0,
        right: isTablet ? AppTheme.spacingXL : 0,
      ),
      itemCount: widgets.length,
      itemBuilder: (context, index) => widgets[index],
    );
  }
}

class _ModernNotificationTile extends StatelessWidget {
  const _ModernNotificationTile({
    required this.notification,
    required this.onTap,
    this.isTablet = false,
  });
  final AppNotification notification;
  final VoidCallback onTap;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    final icon = iconForNotification(notification.type);
    final baseColor = colorForNotification(notification.type);
    final bool isClaimStatus = notification.isClaimStatus;
    final bool isApproved = notification.isClaimApproved;
    final Color chipColor = isApproved
        ? AppTheme.successGreen
        : (isClaimStatus ? AppTheme.errorRed : baseColor);
    final String timeLabel = _formatTime(notification.createdAt);
    final bool isUnread = !notification.isRead;

    // Facebook/Messenger style: Different colors for read vs unread
    // Using AppTheme colors consistently
    final Color titleColor = isUnread ? AppTheme.darkText : AppTheme.textGray;
    final Color bodyColor = isUnread
        ? AppTheme.darkText.withOpacity(0.7)
        : AppTheme.textGray.withOpacity(0.6);
    final Color timeColor = AppTheme.textGray.withOpacity(0.5);
    final Color cardBackground = isUnread ? Colors.white : AppTheme.lightGray;
    final double iconOpacity = isUnread ? 0.2 : 0.1;
    final double iconBorderOpacity = isUnread ? 0.3 : 0.15;

    // Responsive sizing
    final double iconSize = isTablet ? 56 : 48;
    final double iconIconSize = isTablet ? 26 : 24;
    final double titleFontSize = isUnread
        ? (isTablet ? 16 : 15)
        : (isTablet ? 15 : 14);
    final double bodyFontSize = isTablet ? 14 : 13;
    final double horizontalMargin = isTablet
        ? AppTheme.spacingXL
        : AppTheme.spacingL;
    final double horizontalPadding = isTablet
        ? AppTheme.spacingXL
        : AppTheme.spacingL;
    final double verticalPadding = isTablet
        ? AppTheme.spacingL
        : AppTheme.spacingM;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalMargin,
        vertical: AppTheme.spacingXS,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Container(
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: isUnread
                  ? AppTheme.cardShadow
                  : [
                      BoxShadow(
                        color: AppTheme.textGray.withOpacity(0.05),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with subtle background (Facebook style)
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: baseColor.withOpacity(iconOpacity),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: baseColor.withOpacity(iconBorderOpacity),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, color: baseColor, size: iconIconSize),
                  ),
                  SizedBox(width: AppTheme.spacingM),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTheme.bodyLarge.copyWith(
                                  fontWeight: isUnread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: titleColor,
                                  fontSize: titleFontSize,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            if (isClaimStatus)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  isApproved ? 'Approved' : 'Rejected',
                                  style: TextStyle(
                                    color: chipColor,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            if (isUnread)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6, top: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.body,
                          maxLines: isTablet ? 4 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyMedium.copyWith(
                            color: bodyColor,
                            height: 1.4,
                            fontSize: bodyFontSize,
                            fontWeight: isUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXS),
                        Text(
                          timeLabel,
                          style: AppTheme.caption.copyWith(
                            color: timeColor,
                            fontSize: isTablet ? 12 : 11,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(dateTime);
    }
  }
}

class _NotificationGroupHeader extends StatelessWidget {
  const _NotificationGroupHeader({
    required this.title,
    required this.count,
    this.isTablet = false,
  });
  final String title;
  final int count;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isTablet ? AppTheme.spacingXL : AppTheme.spacingL,
        AppTheme.spacingM,
        isTablet ? AppTheme.spacingXL : AppTheme.spacingL,
        AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: isTablet ? 24 : 20,
            decoration: BoxDecoration(
              color: const Color(0xFF123A7D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppTheme.spacingM),
          Text(
            title,
            style: AppTheme.heading4.copyWith(
              fontSize: isTablet ? 18 : 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.mediumAnimation,
        curve: AppTheme.easeOutCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF123A7D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.primaryBlue.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected ? AppTheme.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _NotificationShimmerTile extends StatefulWidget {
  const _NotificationShimmerTile({required this.index, this.isTablet = false});
  final int index;
  final bool isTablet;

  @override
  State<_NotificationShimmerTile> createState() =>
      _NotificationShimmerTileState();
}

class _NotificationShimmerTileState extends State<_NotificationShimmerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      padding: const EdgeInsets.all(AppTheme.spacingL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: widget.isTablet ? 56 : 48,
            height: widget.isTablet ? 56 : 48,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Container(
                  height: 14,
                  width: 200,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 150,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Container(
                  height: 10,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
