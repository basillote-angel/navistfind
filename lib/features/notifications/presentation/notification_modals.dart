import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';
import 'package:navistfind/features/lost_found/item/presentation/claim_status_page.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';

/// Show claim approval notification modal
Future<void> showClaimApprovalModal(
  BuildContext context,
  AppNotification notification,
) async {
  print(
    '[NotificationModals] showClaimApprovalModal called for notification ${notification.id}',
  );
  if (notification.relatedId == null) {
    print('[NotificationModals] No relatedId, showing simple modal');
    await showSimpleNotificationModal(context, notification);
    return;
  }

  print(
    '[NotificationModals] Showing approval modal for item ${notification.relatedId}',
  );
  final claimAsync = await showDialog<ClaimDetail?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      print('[NotificationModals] Building approval modal dialog');
      return _ClaimApprovalModal(
        notification: notification,
        itemId: notification.relatedId!,
      );
    },
  );

  print('[NotificationModals] Approval modal closed, claimAsync: $claimAsync');
  // If user wants to view full details, navigate to claim status page
  if (claimAsync != null && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClaimStatusPage(itemId: notification.relatedId!),
      ),
    );
  }
}

/// Show collection reminder notification modal
Future<void> showCollectionReminderModal(
  BuildContext context,
  AppNotification notification,
) async {
  print(
    '[NotificationModals] showCollectionReminderModal called for notification ${notification.id}',
  );
  if (notification.relatedId == null) {
    await showSimpleNotificationModal(context, notification);
    return;
  }

  print(
    '[NotificationModals] Showing reminder modal for item ${notification.relatedId}',
  );
  final claimAsync = await showDialog<ClaimDetail?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      print('[NotificationModals] Building reminder modal dialog');
      return _CollectionReminderModal(
        notification: notification,
        itemId: notification.relatedId!,
      );
    },
  );

  if (claimAsync != null && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClaimStatusPage(itemId: notification.relatedId!),
      ),
    );
  }
}

/// Show claim rejection notification modal
Future<void> showClaimRejectionModal(
  BuildContext context,
  AppNotification notification,
) async {
  print(
    '[NotificationModals] showClaimRejectionModal called for notification ${notification.id}',
  );
  if (notification.relatedId == null) {
    await showSimpleNotificationModal(context, notification);
    return;
  }

  print(
    '[NotificationModals] Showing rejection modal for item ${notification.relatedId}',
  );
  final claimAsync = await showDialog<ClaimDetail?>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      print('[NotificationModals] Building rejection modal dialog');
      return _ClaimRejectionModal(
        notification: notification,
        itemId: notification.relatedId!,
      );
    },
  );

  if (claimAsync != null && context.mounted) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ClaimStatusPage(itemId: notification.relatedId!),
      ),
    );
  }
}

/// Show claim submitted notification modal with cancel option
Future<void> showClaimSubmittedModal(
  BuildContext context,
  WidgetRef ref,
  AppNotification notification,
) async {
  print(
    '[NotificationModals] showClaimSubmittedModal called for notification ${notification.id}',
  );
  if (notification.relatedId == null) {
    await showSimpleNotificationModal(context, notification);
    return;
  }

  print(
    '[NotificationModals] Showing submitted modal for item ${notification.relatedId}',
  );
  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (dialogContext) {
      print('[NotificationModals] Building submitted modal dialog');
      return _ClaimSubmittedModal(
        notification: notification,
        itemId: notification.relatedId!,
      );
    },
  );
}

/// Simple notification modal for notifications without related items
Future<void> showSimpleNotificationModal(
  BuildContext context,
  AppNotification notification,
) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SimpleNotificationModal(notification: notification),
  );
}

/// Claim Approval Modal
class _ClaimApprovalModal extends ConsumerWidget {
  const _ClaimApprovalModal({required this.notification, required this.itemId});

  final AppNotification notification;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('[NotificationModals] _ClaimApprovalModal building for item $itemId');
    final claimAsync = ref.watch(claimDetailProvider(itemId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          minWidth: 300,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: claimAsync.when(
            loading: () {
              print('[NotificationModals] Loading claim details...');
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, _) {
              print('[NotificationModals] Error loading claim: $error');
              return _ApprovalContentFallback(
                notification: notification,
                error: error,
              );
            },
            data: (claim) {
              print(
                '[NotificationModals] Claim loaded successfully: ${claim.id}',
              );
              return _ApprovalContent(claim: claim, notification: notification);
            },
          ),
        ),
      ),
    );
  }
}

class _ApprovalContent extends StatelessWidget {
  const _ApprovalContent({required this.claim, required this.notification});

  final ClaimDetail claim;
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final deadline = claim.collectionDeadline;
    final deadlineFormatted = deadline != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(deadline)
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.successGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Approved',
                style: AppTheme.heading3.copyWith(color: AppTheme.successGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Message
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageSection(message: notification.body),
                const SizedBox(height: 16),
                if (claim.foundItemTitle != null)
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item',
                    value: claim.foundItemTitle!,
                  ),
                if (claim.collectionLocation != null)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup Location',
                    value: claim.collectionLocation!,
                  ),
                if (deadlineFormatted != null)
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Deadline',
                    value: deadlineFormatted,
                    isUrgent:
                        deadline != null &&
                        DateTime.now()
                            .add(const Duration(days: 1))
                            .isAfter(deadline),
                  ),
                if (claim.collectionInstructions != null &&
                    claim.collectionInstructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _CollectionInstructionsSection(
                    instructions: claim.collectionInstructions!,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Actions - Only Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Collection Reminder Modal
class _CollectionReminderModal extends ConsumerWidget {
  const _CollectionReminderModal({
    required this.notification,
    required this.itemId,
  });

  final AppNotification notification;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(claimDetailProvider(itemId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: claimAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ReminderContentFallback(
              notification: notification,
              error: error,
            ),
            data: (claim) =>
                _ReminderContent(claim: claim, notification: notification),
          ),
        ),
      ),
    );
  }
}

class _ReminderContent extends StatelessWidget {
  const _ReminderContent({required this.claim, required this.notification});

  final ClaimDetail claim;
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final deadline = claim.collectionDeadline;
    final isUrgent =
        deadline != null &&
        DateTime.now().add(const Duration(days: 1)).isAfter(deadline);
    final isOverdue = deadline != null && DateTime.now().isAfter(deadline);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color:
                      (isOverdue || isUrgent
                              ? AppTheme.errorRed
                              : AppTheme.warningOrange)
                          .withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOverdue ? Icons.warning_amber_rounded : Icons.access_time,
                  color: isOverdue || isUrgent
                      ? AppTheme.errorRed
                      : AppTheme.warningOrange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : (isOverdue
                          ? 'Collection Overdue'
                          : (isUrgent
                                ? 'Urgent Reminder'
                                : 'Collection Reminder')),
                style: AppTheme.heading3.copyWith(
                  color: isOverdue || isUrgent
                      ? AppTheme.errorRed
                      : AppTheme.warningOrange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Message
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The collection deadline has passed. Please contact the admin office immediately.',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.errorRed,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                _MessageSection(message: notification.body),
                const SizedBox(height: 16),
                if (claim.foundItemTitle != null)
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item',
                    value: claim.foundItemTitle!,
                  ),
                if (claim.collectionLocation != null)
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Pickup Location',
                    value: claim.collectionLocation!,
                  ),
                if (deadline != null)
                  _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Deadline',
                    value: DateFormat('MMM d, yyyy • h:mm a').format(deadline),
                    isUrgent: isUrgent || isOverdue,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Actions - Only Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Claim Rejection Modal
class _ClaimRejectionModal extends ConsumerWidget {
  const _ClaimRejectionModal({
    required this.notification,
    required this.itemId,
  });

  final AppNotification notification;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(claimDetailProvider(itemId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: claimAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _RejectionContentFallback(
              notification: notification,
              error: error,
            ),
            data: (claim) =>
                _RejectionContent(claim: claim, notification: notification),
          ),
        ),
      ),
    );
  }
}

class _RejectionContent extends StatelessWidget {
  const _RejectionContent({required this.claim, required this.notification});

  final ClaimDetail claim;
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.highlight_off_rounded,
                  color: AppTheme.errorRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Rejected',
                style: AppTheme.heading3.copyWith(color: AppTheme.errorRed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Message
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MessageSection(message: notification.body),
                const SizedBox(height: 16),
                if (claim.rejectionReason != null &&
                    claim.rejectionReason!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rejection Reason:',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          claim.rejectionReason!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if (claim.foundItemTitle != null)
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item',
                    value: claim.foundItemTitle!,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Actions - Only Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Claim Submitted Modal with Cancel Option
class _ClaimSubmittedModal extends ConsumerWidget {
  const _ClaimSubmittedModal({
    required this.notification,
    required this.itemId,
  });

  final AppNotification notification;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(claimDetailProvider(itemId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: claimAsync.when<Widget>(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) {
              return _SubmittedContentFallback(
                notification: notification,
                itemId: itemId,
                error: error,
              );
            },
            data: (claim) => _SubmittedContent(
              claim: claim,
              notification: notification,
              itemId: itemId,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubmittedContent extends ConsumerWidget {
  const _SubmittedContent({
    required this.claim,
    required this.notification,
    required this.itemId,
  });

  final ClaimDetail claim;
  final AppNotification notification;
  final int itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final submittedAt = dateFormat.format(claim.submittedAt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_outlined,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Submitted',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Message
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display the enhanced formal message from backend
                _MessageSection(message: notification.body),
                const SizedBox(height: 16),
                if (claim.foundItemTitle != null)
                  _InfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Item',
                    value: claim.foundItemTitle!,
                  ),
                _InfoRow(
                  icon: Icons.access_time_outlined,
                  label: 'Submitted',
                  value: submittedAt,
                ),
                if (claim.message.isNotEmpty)
                  _InfoRow(
                    icon: Icons.message_outlined,
                    label: 'Your Message',
                    value: claim.message,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Actions - Only Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Simple Notification Modal
class _SimpleNotificationModal extends StatelessWidget {
  const _SimpleNotificationModal({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notification.title,
              style: AppTheme.heading4,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              notification.body,
              style: AppTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Approval Content Fallback (when claim details fail to load)
class _ApprovalContentFallback extends StatelessWidget {
  const _ApprovalContentFallback({
    required this.notification,
    required this.error,
  });

  final AppNotification notification;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final isNotFound =
        error.toString().contains('404') ||
        error.toString().contains('not found');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: AppTheme.successGreen,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Approved',
                style: AppTheme.heading3.copyWith(color: AppTheme.successGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isNotFound)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item details are no longer available, but your claim was approved.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: _MessageSection(message: notification.body),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Reminder Content Fallback
class _ReminderContentFallback extends StatelessWidget {
  const _ReminderContentFallback({
    required this.notification,
    required this.error,
  });

  final AppNotification notification;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final isNotFound =
        error.toString().contains('404') ||
        error.toString().contains('not found');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  color: AppTheme.warningOrange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Collection Reminder',
                style: AppTheme.heading3.copyWith(
                  color: AppTheme.warningOrange,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isNotFound)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item details are no longer available.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: _MessageSection(message: notification.body),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Rejection Content Fallback
class _RejectionContentFallback extends StatelessWidget {
  const _RejectionContentFallback({
    required this.notification,
    required this.error,
  });

  final AppNotification notification;
  final Object error;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);
    final isNotFound =
        error.toString().contains('404') ||
        error.toString().contains('not found');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.highlight_off_rounded,
                  color: AppTheme.errorRed,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Rejected',
                style: AppTheme.heading3.copyWith(color: AppTheme.errorRed),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (isNotFound)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.errorRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppTheme.errorRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item details are no longer available.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            child: _MessageSection(message: notification.body),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Submitted Content Fallback
class _SubmittedContentFallback extends ConsumerWidget {
  const _SubmittedContentFallback({
    required this.notification,
    required this.itemId,
    required this.error,
  });

  final AppNotification notification;
  final int itemId;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final sentAt = dateFormat.format(notification.createdAt);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pending_outlined,
                  color: AppTheme.primaryBlue,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                notification.title.isNotEmpty
                    ? notification.title
                    : 'Claim Submitted',
                style: AppTheme.heading3.copyWith(color: AppTheme.primaryBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $sentAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: _MessageSection(message: notification.body),
          ),
        ),
        const SizedBox(height: 16),
        // Actions - Only Close button
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Message Section Widget - Formatted and Readable
class _MessageSection extends StatelessWidget {
  const _MessageSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final lines = message
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse formatted sections from enhanced formal messages
    final List<Widget> widgets = [];
    String? currentSection;
    List<String> currentSectionLines = [];
    bool inSection = false;

    for (final line in lines) {
      // Check if it's a section header (contains ━━ or is all caps like "NEXT STEPS", "PICKUP INSTRUCTIONS")
      if (line.contains('━━')) {
        // Separator line - save previous section if exists
        if (currentSection != null && currentSectionLines.isNotEmpty) {
          widgets.add(_buildSection(currentSection, currentSectionLines));
          currentSectionLines = [];
          currentSection = null;
        }
        inSection = false;
        continue; // Skip separator lines
      } else if (line.length > 2 &&
          line == line.toUpperCase() &&
          !line.contains(':') &&
          !line.startsWith('Dear') &&
          !line.contains('━━')) {
        // Section header (all caps, no colon, not greeting)
        // Save previous section
        if (currentSection != null && currentSectionLines.isNotEmpty) {
          widgets.add(_buildSection(currentSection, currentSectionLines));
          currentSectionLines = [];
        }
        currentSection = line;
        inSection = true;
      } else if (line.startsWith('Dear')) {
        // Greeting line - format as emphasized paragraph
        // Save any previous section first
        if (currentSection != null && currentSectionLines.isNotEmpty) {
          widgets.add(_buildSection(currentSection, currentSectionLines));
          currentSectionLines = [];
          currentSection = null;
        }
        inSection = false;
        widgets.add(_buildGreeting(line));
      } else if (line.startsWith('📍') ||
          line.startsWith('🕐') ||
          line.startsWith('⏰') ||
          line.startsWith('📋') ||
          line.startsWith('📝') ||
          line.startsWith('⚠️') ||
          line.startsWith('📞') ||
          line.startsWith('🚨')) {
        // Emoji-prefixed lines (info items)
        if (inSection && currentSection != null) {
          currentSectionLines.add(line);
        } else {
          widgets.add(_buildInfoItem(line));
        }
      } else if (line.startsWith('•') || line.startsWith('-')) {
        // Bullet points
        if (inSection && currentSection != null) {
          currentSectionLines.add(line);
        } else {
          widgets.add(_buildBulletPoint(line));
        }
      } else if (line.contains(':') && !line.startsWith('Dear')) {
        // Key-value pairs (but not greeting)
        final parts = line.split(':');
        if (parts.length >= 2) {
          if (inSection && currentSection != null) {
            currentSectionLines.add(line);
          } else {
            widgets.add(
              _buildKeyValue(
                parts[0].trim(),
                parts.sublist(1).join(':').trim(),
              ),
            );
          }
        } else {
          if (inSection && currentSection != null) {
            currentSectionLines.add(line);
          } else {
            widgets.add(_buildParagraph(line));
          }
        }
      } else {
        // Regular paragraph
        if (inSection && currentSection != null) {
          currentSectionLines.add(line);
        } else {
          // Check if it's a closing line (Best regards, etc.)
          if (line.toLowerCase().contains('best regards') ||
              (line.toLowerCase().contains('thank you') &&
                  !line.toLowerCase().startsWith('thank you for')) ||
              line.toLowerCase().contains('navistfind administration') ||
              line.toLowerCase().contains('carmen national high school')) {
            widgets.add(_buildClosing(line));
          } else {
            widgets.add(_buildParagraph(line));
          }
        }
      }
    }

    // Add last section if exists
    if (currentSection != null && currentSectionLines.isNotEmpty) {
      widgets.add(_buildSection(currentSection, currentSectionLines));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildSection(String title, List<String> lines) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading4.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                line,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkText),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              line,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String line) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18)),
          Expanded(
            child: Text(
              line.substring(1).trim(),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.darkText,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParagraph(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        line,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.darkText,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildGreeting(String line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        line,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.darkText,
          height: 1.6,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildClosing(String line) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        line,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textGray,
          height: 1.6,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// Info Row Widget
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isUrgent ? AppTheme.errorRed : AppTheme.textGray,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isUrgent ? AppTheme.errorRed : AppTheme.darkText,
                    fontWeight: isUrgent ? FontWeight.w600 : FontWeight.normal,
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

/// Clean and simple collection instructions display
class _CollectionInstructionsSection extends StatelessWidget {
  const _CollectionInstructionsSection({required this.instructions});

  final String instructions;

  @override
  Widget build(BuildContext context) {
    // Split instructions into lines and clean them
    final lines = instructions
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Collection Instructions',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlue,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...lines.map((line) {
            // Check if it's a bullet point
            final isBullet =
                line.startsWith('•') ||
                line.startsWith('-') ||
                line.startsWith('*');

            // Remove bullet markers
            final cleanLine = isBullet
                ? line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '')
                : line;

            return Padding(
              padding: EdgeInsets.only(
                bottom: isBullet ? 8 : 10,
                left: isBullet ? 8 : 0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isBullet)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      cleanLine,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppTheme.darkText,
                        height: 1.6,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
