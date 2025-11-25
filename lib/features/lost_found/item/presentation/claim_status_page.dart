import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/snackbar_utils.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';
import 'package:navistfind/features/lost_found/item/application/claim_status_cache_provider.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/profile/domain/models/claim_request.dart';
import 'package:navistfind/features/profile/presentation/edit_claim_request_page.dart';
import 'claim_item.dart';

class ClaimStatusPage extends ConsumerStatefulWidget {
  const ClaimStatusPage({super.key, required this.itemId});

  final int itemId;

  @override
  ConsumerState<ClaimStatusPage> createState() => _ClaimStatusPageState();
}

class _ClaimStatusPageState extends ConsumerState<ClaimStatusPage> {
  @override
  Widget build(BuildContext context) {
    final claimAsync = ref.watch(claimDetailProvider(widget.itemId));

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Claim Status',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(claimDetailProvider(widget.itemId));
            await ref.read(claimDetailProvider(widget.itemId).future);
          },
          color: AppTheme.primaryBlue,
          backgroundColor: Colors.white,
          strokeWidth: 3.0,
          displacement: 40.0,
          child: claimAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
            ),
            error: (error, stackTrace) {
              print(
                '[ClaimStatusPage] Error loading claim for item ${widget.itemId}: $error',
              );
              if (error is DioException) {
                print(
                  '[ClaimStatusPage] DioException details: ${error.message}',
                );
                print('[ClaimStatusPage] Response: ${error.response?.data}');
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: 300,
                    child: _ErrorState(
                      onRetry: () =>
                          ref.invalidate(claimDetailProvider(widget.itemId)),
                      message: _getErrorMessage(error),
                    ),
                  ),
                ],
              );
            },
            data: (claim) {
              // Update cache after build completes (can't modify providers during build)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final cacheNotifier = ref.read(
                  claimStatusCacheProvider.notifier,
                );
                if (claim.status == ClaimStatus.withdrawn) {
                  cacheNotifier.clear(widget.itemId);
                } else {
                  cacheNotifier.setStatus(widget.itemId, claim.status);
                }
              });

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildClaimView(claim),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildClaimView(ClaimDetail claim) {
    switch (claim.status) {
      case ClaimStatus.pending:
        return _PendingClaimView(itemId: widget.itemId, claim: claim);
      case ClaimStatus.approved:
        return _ApprovedClaimView(claim: claim);
      case ClaimStatus.rejected:
        return _RejectedClaimView(itemId: widget.itemId, claim: claim);
      case ClaimStatus.withdrawn:
        return _WithdrawnClaimView(claim: claim);
    }
  }
}

class _PendingClaimView extends ConsumerWidget {
  const _PendingClaimView({required this.itemId, required this.claim});

  final int itemId;
  final ClaimDetail claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat(
      'MMM d, yyyy • h:mm a',
    ).format(claim.submittedAt);
    final allowEdit = claim.canEdit;
    final allowCancel = claim.canCancel;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            icon: Icons.hourglass_top,
            color: AppTheme.warningOrange,
            title: 'Pending Review',
            subtitle:
                'An admin is reviewing your claim. You can update your details or cancel the request below.',
          ),
          const SizedBox(height: 20),
          _DetailCard(
            title: 'Claim Details',
            children: [
              if (claim.foundItemTitle != null &&
                  claim.foundItemTitle!.isNotEmpty)
                _DetailRow(label: 'Item', value: claim.foundItemTitle!),
              _DetailRow(label: 'Submitted', value: formattedDate),
              _DetailRow(label: 'Message', value: claim.message),
              if (claim.claimantName != null && claim.claimantName!.isNotEmpty)
                _DetailRow(label: 'Contact Name', value: claim.claimantName!),
              if (claim.claimantContact != null &&
                  claim.claimantContact!.isNotEmpty)
                _DetailRow(
                  label: 'Contact Info',
                  value: claim.claimantContact!,
                ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Edit Claim Details',
            icon: Icons.edit_outlined,
            enabled: allowEdit,
            onPressed: () async {
              if (!allowEdit) return;
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => EditClaimRequestPage(
                    claim: ClaimRequest.fromDetail(claim),
                  ),
                ),
              );
              if (result == true && context.mounted) {
                ref.invalidate(claimDetailProvider(itemId));
                SnackbarUtils.showSuccess(
                  context,
                  'Claim details updated successfully.',
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            label: 'Cancel Claim',
            icon: Icons.cancel_outlined,
            enabled: allowCancel,
            isPrimary: false,
            destructive: true,
            onPressed: () async {
              if (!allowCancel) return;
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  title: const Text('Cancel claim?'),
                  content: const Text(
                    'This will withdraw your claim request. You can file a new claim later if needed.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Keep Claim'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorRed,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Cancel Claim'),
                    ),
                  ],
                ),
              );

              if (confirmed != true || !context.mounted) return;

              final notifier = ref.read(claimRequestsProvider.notifier);
              final error = await notifier.cancelClaim(itemId: itemId);
              if (!context.mounted) return;

              if (error == null) {
                ref.read(claimStatusCacheProvider.notifier).clear(itemId);
                ref.invalidate(itemsByTypeProvider(ItemType.found));
                ref.invalidate(itemListProvider);
                SnackbarUtils.showSuccess(
                  context,
                  'Your claim has been withdrawn.',
                );
                Navigator.of(context).pop(true);
              } else {
                SnackbarUtils.showError(context, error);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ApprovedClaimView extends StatefulWidget {
  const _ApprovedClaimView({required this.claim});

  final ClaimDetail claim;

  @override
  State<_ApprovedClaimView> createState() => _ApprovedClaimViewState();
}

class _ApprovedClaimViewState extends State<_ApprovedClaimView> {
  @override
  Widget build(BuildContext context) {
    final deadline = widget.claim.collectionDeadline;
    final now = DateTime.now();
    final isOverdue = deadline != null && now.isAfter(deadline);
    final timeRemaining = deadline != null ? deadline.difference(now) : null;
    final isUrgent =
        timeRemaining != null &&
        timeRemaining.inHours < 24 &&
        timeRemaining.inHours >= 0;
    final isVeryUrgent =
        timeRemaining != null &&
        timeRemaining.inHours < 1 &&
        timeRemaining.inHours >= 0;

    final deadlineFormatted = deadline != null
        ? DateFormat('MMM d, yyyy • h:mm a').format(deadline)
        : null;

    // Determine urgency color and message
    Color urgencyColor;
    String urgencyMessage;
    IconData urgencyIcon;

    if (isOverdue) {
      urgencyColor = AppTheme.errorRed;
      urgencyMessage =
          'Deadline has passed. Please contact the admin office immediately.';
      urgencyIcon = Icons.warning_amber_rounded;
    } else if (isVeryUrgent) {
      urgencyColor = AppTheme.errorRed;
      urgencyMessage =
          'Less than 1 hour remaining! Please collect immediately.';
      urgencyIcon = Icons.access_time_filled;
    } else if (isUrgent) {
      urgencyColor = AppTheme.warningOrange;
      urgencyMessage = 'Less than 24 hours remaining. Please collect soon.';
      urgencyIcon = Icons.access_time;
    } else {
      urgencyColor = AppTheme.primaryBlue;
      urgencyMessage =
          'Bring a valid ID and any supporting evidence when you pick up the item.';
      urgencyIcon = Icons.info_outline;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            icon: Icons.assignment_turned_in_outlined,
            color: AppTheme.successGreen,
            title: 'Claim Approved',
            subtitle:
                'Great news! The admin approved your claim. Review the pickup instructions below.',
          ),
          const SizedBox(height: 20),

          // Urgency/Deadline warning banner
          if (deadline != null && (isOverdue || isUrgent || isVeryUrgent))
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: urgencyColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: urgencyColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(urgencyIcon, color: urgencyColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverdue
                              ? 'Collection Overdue'
                              : (isVeryUrgent
                                    ? 'Urgent: Collect Now'
                                    : 'Deadline Approaching'),
                          style: AppTheme.heading4.copyWith(
                            color: urgencyColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          urgencyMessage,
                          style: AppTheme.bodySmall.copyWith(
                            color: urgencyColor.withOpacity(0.9),
                          ),
                        ),
                        if (timeRemaining != null && !isOverdue) ...[
                          const SizedBox(height: 8),
                          Text(
                            _formatTimeRemaining(timeRemaining),
                            style: AppTheme.bodyMedium.copyWith(
                              color: urgencyColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

          _DetailCard(
            title: 'Pickup Instructions',
            children: [
              if (widget.claim.foundItemTitle != null &&
                  widget.claim.foundItemTitle!.isNotEmpty)
                _DetailRow(label: 'Item', value: widget.claim.foundItemTitle!),
              if (widget.claim.collectionInstructions != null &&
                  widget.claim.collectionInstructions!.isNotEmpty)
                _DetailRow(
                  label: 'Instructions',
                  value: widget.claim.collectionInstructions!,
                ),
              if (widget.claim.collectionLocation != null &&
                  widget.claim.collectionLocation!.isNotEmpty)
                _DetailRow(
                  label: 'Pickup Location',
                  value: widget.claim.collectionLocation!,
                ),
              if (deadlineFormatted != null)
                _DetailRow(
                  label: 'Pickup Deadline',
                  value: deadlineFormatted,
                  isUrgent: isUrgent || isVeryUrgent || isOverdue,
                ),
              if (widget.claim.adminNotes != null &&
                  widget.claim.adminNotes!.isNotEmpty)
                _DetailRow(
                  label: 'Admin Notes',
                  value: widget.claim.adminNotes!,
                ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(urgencyIcon, color: urgencyColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    urgencyMessage,
                    style: AppTheme.bodySmall.copyWith(color: urgencyColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} remaining';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} remaining';
    } else {
      return 'Less than a minute remaining';
    }
  }
}

class _RejectedClaimView extends ConsumerWidget {
  const _RejectedClaimView({required this.itemId, required this.claim});

  final int itemId;
  final ClaimDetail claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            icon: Icons.highlight_off_outlined,
            color: AppTheme.errorRed,
            title: 'Claim Rejected',
            subtitle:
                'Your claim was rejected. Review the notes below and adjust your evidence before submitting a new claim.',
          ),
          const SizedBox(height: 20),
          _DetailCard(
            title: 'Review Notes',
            children: [
              if (claim.foundItemTitle != null &&
                  claim.foundItemTitle!.isNotEmpty)
                _DetailRow(label: 'Item', value: claim.foundItemTitle!),
              if (claim.rejectionReason != null &&
                  claim.rejectionReason!.isNotEmpty)
                _DetailRow(label: 'Reason', value: claim.rejectionReason!),
              if (claim.adminNotes != null && claim.adminNotes!.isNotEmpty)
                _DetailRow(label: 'Admin Notes', value: claim.adminNotes!),
              _DetailRow(
                label: 'Submitted',
                value: DateFormat(
                  'MMM d, yyyy • h:mm a',
                ).format(claim.submittedAt),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _ActionButton(
            label: 'Submit New Claim',
            icon: Icons.refresh_outlined,
            onPressed: () async {
              ref.read(claimStatusCacheProvider.notifier).clear(itemId);
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => ClaimItemPage(itemId: itemId),
                ),
              );
              if (result == true && context.mounted) {
                ref.invalidate(claimDetailProvider(itemId));
              }
            },
          ),
        ],
      ),
    );
  }
}

class _WithdrawnClaimView extends StatelessWidget {
  const _WithdrawnClaimView({required this.claim});

  final ClaimDetail claim;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusHeader(
            icon: Icons.info_outline,
            color: AppTheme.textGray,
            title: 'Claim Withdrawn',
            subtitle:
                'You withdrew this claim. You can submit a new one if you still believe the item is yours.',
          ),
          const SizedBox(height: 20),
          _DetailCard(
            title: 'Summary',
            children: [
              if (claim.foundItemTitle != null &&
                  claim.foundItemTitle!.isNotEmpty)
                _DetailRow(label: 'Item', value: claim.foundItemTitle!),
              _DetailRow(
                label: 'Submitted',
                value: DateFormat(
                  'MMM d, yyyy • h:mm a',
                ).format(claim.submittedAt),
              ),
              _DetailRow(label: 'Message', value: claim.message),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.heading3.copyWith(color: color, fontSize: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.darkText.withOpacity(0.75),
                    height: 1.5,
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading4.copyWith(fontSize: 17)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isUrgent = false,
  });

  final String label;
  final String value;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: isUrgent ? AppTheme.errorRed : AppTheme.darkText,
              fontWeight: isUrgent ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = true,
    this.destructive = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool destructive;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: enabled ? onPressed : null,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: destructive
                ? AppTheme.errorRed
                : AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          color: destructive
              ? AppTheme.errorRed
              : enabled
              ? AppTheme.darkText
              : AppTheme.textGray,
        ),
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: destructive
                ? AppTheme.errorRed
                : enabled
                ? AppTheme.darkText
                : AppTheme.textGray,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: destructive
                ? AppTheme.errorRed.withOpacity(0.6)
                : AppTheme.primaryBlue.withOpacity(enabled ? 0.4 : 0.2),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }
}

String _getErrorMessage(dynamic error) {
  if (error is DioException) {
    final message = error.message ?? error.toString();
    if (message.contains('No active claim')) {
      return 'No active claim found for this item. The claim may have been cancelled or expired.';
    }
    if (message.contains('Failed to parse')) {
      return 'Unable to load claim details. Please try again or contact support if the issue persists.';
    }
    if (error.response?.statusCode == 404) {
      return 'Item not found. The item may have been deleted.';
    }
    if (error.response?.statusCode == 500) {
      return 'Server error. Please try again later.';
    }
    return 'Failed to load claim: $message';
  }
  return error is Exception ? error.toString() : '$error';
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed, size: 48),
            const SizedBox(height: 12),
            Text(
              'Unable to load claim',
              style: AppTheme.heading4.copyWith(color: AppTheme.errorRed),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textGray,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
