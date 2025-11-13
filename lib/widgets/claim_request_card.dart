import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/profile/domain/models/claim_request.dart';
import 'package:navistfind/widgets/nf_card.dart';

class ClaimRequestCard extends StatelessWidget {
  const ClaimRequestCard({super.key, required this.claim, required this.onTap});

  final ClaimRequest claim;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foundItem = claim.foundItem;

    return NfCard(
      radius: AppTheme.radiusLarge,
      backgroundColor: Colors.white,
      border: Border.all(
        color: AppTheme.primaryBlue.withOpacity(0.06),
        width: 0.8,
      ),
      shadows: AppTheme.cardShadow,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: AppTheme.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    foundItem?.title ?? 'Claim Request',
                    style: AppTheme.heading4.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (foundItem?.location != null &&
                      foundItem!.location!.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppTheme.textGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            foundItem.location!,
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.textGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatusChip(status: claim.status),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ClaimRequestStatus status;

  Color get _background {
    switch (status) {
      case ClaimRequestStatus.pending:
        return AppTheme.warningOrange.withOpacity(0.12);
      case ClaimRequestStatus.approved:
        return AppTheme.successGreen.withOpacity(0.12);
      case ClaimRequestStatus.rejected:
        return AppTheme.errorRed.withOpacity(0.12);
      case ClaimRequestStatus.withdrawn:
        return AppTheme.textGray.withOpacity(0.12);
    }
  }

  Color get _textColor {
    switch (status) {
      case ClaimRequestStatus.pending:
        return AppTheme.warningOrange;
      case ClaimRequestStatus.approved:
        return AppTheme.successGreen;
      case ClaimRequestStatus.rejected:
        return AppTheme.errorRed;
      case ClaimRequestStatus.withdrawn:
        return AppTheme.textGray;
    }
  }

  IconData get _icon {
    switch (status) {
      case ClaimRequestStatus.pending:
        return Icons.hourglass_top_outlined;
      case ClaimRequestStatus.approved:
        return Icons.check_circle_outline;
      case ClaimRequestStatus.rejected:
        return Icons.cancel_outlined;
      case ClaimRequestStatus.withdrawn:
        return Icons.remove_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 16, color: _textColor),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: AppTheme.caption.copyWith(
              color: _textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
