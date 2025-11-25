import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
    this.itemType,
    this.padding,
    this.fontSize,
  });

  final ItemStatus status;
  final ItemType? itemType;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    final _StatusVisuals visuals = _computeVisuals(status, itemType);
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: visuals.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(visuals.icon, size: (fontSize ?? 12) + 2, color: visuals.color),
          const SizedBox(width: 4),
          Text(
            visuals.label,
            style: TextStyle(
              color: visuals.color,
              fontWeight: FontWeight.w700,
              fontSize: fontSize ?? 12,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  _StatusVisuals _computeVisuals(ItemStatus status, ItemType? itemType) {
    switch (status) {
      case ItemStatus.lostReported:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.search_rounded,
          color: AppTheme.warningOrange,
        );
      case ItemStatus.resolved:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.verified_outlined,
          color: AppTheme.successGreen,
        );
      case ItemStatus.foundUnclaimed:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.inventory_2_outlined,
          color: AppTheme.primaryBlue,
        );
      case ItemStatus.claimPending:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.hourglass_top_rounded,
          color: AppTheme.warningOrange,
        );
      case ItemStatus.claimApproved:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.assignment_turned_in_outlined,
          color: AppTheme.successGreen,
        );
      case ItemStatus.collected:
        return _StatusVisuals(
          label: status.displayLabel.toUpperCase(),
          icon: Icons.inventory_outlined,
          color: AppTheme.textGray,
        );
    }
  }
}

class _StatusVisuals {
  final String label;
  final IconData icon;
  final Color color;
  const _StatusVisuals({
    required this.label,
    required this.icon,
    required this.color,
  });
}
