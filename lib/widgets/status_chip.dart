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
    final bool isLost = itemType == ItemType.lost;
    switch (status) {
      case ItemStatus.returned:
        return const _StatusVisuals(
          label: 'RETURNED',
          icon: Icons.check_circle,
          color: AppTheme.successGreen,
        );
      case ItemStatus.matched:
        return const _StatusVisuals(
          label: 'POTENTIAL MATCH',
          icon: Icons.search,
          color: AppTheme.primaryBlue,
        );
      case ItemStatus.open:
        return _StatusVisuals(
          label: isLost ? 'SEARCHING' : 'AVAILABLE',
          icon: isLost ? Icons.search : Icons.notifications_active,
          color: isLost ? AppTheme.warningOrange : AppTheme.primaryBlue,
        );
      case ItemStatus.unclaimed:
        return const _StatusVisuals(
          label: 'NOT CLAIMED',
          icon: Icons.cancel_outlined,
          color: AppTheme.errorRed,
        );
      case ItemStatus.closed:
        return _StatusVisuals(
          label: 'EXPIRED',
          icon: Icons.access_time,
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
