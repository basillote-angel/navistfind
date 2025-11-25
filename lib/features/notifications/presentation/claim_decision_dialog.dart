import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';
import 'package:navistfind/features/lost_found/item/presentation/claim_status_page.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';

class ClaimDecisionDialog extends ConsumerWidget {
  const ClaimDecisionDialog({
    super.key,
    required this.itemId,
    required this.notification,
  });

  final int itemId;
  final AppNotification notification;

  bool get _isApprovedHint => notification.isClaimApproved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claimAsync = ref.watch(claimDetailProvider(itemId));
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          minHeight: MediaQuery.of(context).size.height * 0.30,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: claimAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ClaimDecisionError(
              message: error is Exception ? error.toString() : '$error',
              notification: notification,
            ),
            data: (claim) => _ClaimDecisionContent(
              claim: claim,
              notification: notification,
              isApprovedHint: _isApprovedHint,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClaimDecisionContent extends StatelessWidget {
  const _ClaimDecisionContent({
    required this.claim,
    required this.notification,
    required this.isApprovedHint,
  });

  final ClaimDetail claim;
  final AppNotification notification;
  final bool isApprovedHint;

  @override
  Widget build(BuildContext context) {
    final status = claim.status;
    final bool isApproved = status == ClaimStatus.approved || isApprovedHint;
    final bool isRejected =
        status == ClaimStatus.rejected ||
        (!isApproved && status != ClaimStatus.approved);
    final Color statusColor = isApproved
        ? AppTheme.successGreen
        : (isRejected ? AppTheme.errorRed : AppTheme.primaryBlue);
    final IconData statusIcon = isApproved
        ? Icons.verified_rounded
        : (isRejected ? Icons.highlight_off_rounded : Icons.info_outline);

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final String submittedAt = dateFormat.format(claim.submittedAt);
    final String createdAt = dateFormat.format(notification.createdAt);

    final List<Widget> bodyLines = _buildMessageLines(notification.body);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                isApproved
                    ? 'Claim Approved'
                    : (isRejected ? 'Claim Rejected' : notification.title),
                style: AppTheme.heading3.copyWith(color: statusColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sent $createdAt',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailSection(
                  title: 'Item',
                  children: [
                    _DetailRow(
                      label: 'Title',
                      value: claim.foundItemTitle ?? 'Item #${claim.itemId}',
                    ),
                    _DetailRow(label: 'Submitted', value: submittedAt),
                  ],
                ),
                if (claim.collectionLocation != null ||
                    claim.collectionInstructions != null ||
                    claim.collectionDeadline != null)
                  _DetailSection(
                    title: 'Pickup Instructions',
                    children: [
                      if (claim.collectionLocation != null &&
                          claim.collectionLocation!.isNotEmpty)
                        _DetailRow(
                          label: 'Location',
                          value: claim.collectionLocation!,
                        ),
                      if (claim.collectionDeadline != null)
                        _DetailRow(
                          label: 'Pickup By',
                          value: DateFormat(
                            'MMM d, yyyy',
                          ).format(claim.collectionDeadline!),
                        ),
                      if (claim.collectionInstructions != null &&
                          claim.collectionInstructions!.isNotEmpty)
                        _DetailRow(
                          label: 'Notes',
                          value: claim.collectionInstructions!,
                        ),
                      if (claim.adminNotes != null &&
                          claim.adminNotes!.isNotEmpty)
                        _DetailRow(
                          label: 'Admin Notes',
                          value: claim.adminNotes!,
                        ),
                    ],
                  ),
                if (claim.rejectionReason != null &&
                    claim.rejectionReason!.isNotEmpty)
                  _DetailSection(
                    title: 'Why it was rejected',
                    children: [_ParagraphText(claim.rejectionReason!)],
                  ),
                if (bodyLines.isNotEmpty)
                  _DetailSection(
                    title: 'Message from admin',
                    children: bodyLines,
                  ),
                _DetailSection(
                  title: 'Contact',
                  children: [
                    _DetailRow(
                      label: 'Name',
                      value: claim.claimantName ?? 'You',
                    ),
                    if (claim.claimantContact != null &&
                        claim.claimantContact!.isNotEmpty)
                      _DetailRow(
                        label: 'Contact Info',
                        value: claim.claimantContact!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClaimStatusPage(itemId: claim.itemId),
                  ),
                );
              },
              child: const Text('View Claim Timeline'),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildMessageLines(String message) {
    final lines = message
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      return const [];
    }
    return lines
        .map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _ParagraphText(line),
          ),
        )
        .toList();
  }
}

class _ClaimDecisionError extends StatelessWidget {
  const _ClaimDecisionError({
    required this.message,
    required this.notification,
  });

  final String message;
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final List<Widget> bodyLines = notification.body.trim().isNotEmpty
        ? notification.body
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _ParagraphText(line),
                ),
              )
              .toList()
        : const [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.errorRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unable to load claim details',
                style: AppTheme.heading4.copyWith(color: AppTheme.errorRed),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ParagraphText('Error: $message'),
        const SizedBox(height: 12),
        if (bodyLines.isNotEmpty)
          _DetailSection(title: 'Message from admin', children: bodyLines),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.heading4.copyWith(color: AppTheme.primaryBlue),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: _ParagraphText(value)),
        ],
      ),
    );
  }
}

class _ParagraphText extends StatelessWidget {
  const _ParagraphText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTheme.bodyMedium.copyWith(color: AppTheme.darkText),
    );
  }
}
