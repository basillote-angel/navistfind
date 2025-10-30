import 'package:flutter/material.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/widgets/nf_card.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/core/utils/date_formatter.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

class PostedItemCard extends StatelessWidget {
  const PostedItemCard({
    super.key,
    required this.postedItem,
    required this.onTap,
    this.onLongPress,
    this.cardWidth = 190,
    this.headerHeight = 110,
    this.radius = 16,
    this.borderOpacity = 0.04,
    this.borderWidth = 0.5,
    this.iconSize = 42,
    this.titleFontSize = 15,
    this.chipFontSize = 10,
  });

  final PostedItem postedItem;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double cardWidth;
  final double headerHeight;
  final double radius;
  final double borderOpacity;
  final double borderWidth;
  final double iconSize;
  final double titleFontSize;
  final double chipFontSize;

  static const Color darkBlue = AppTheme.primaryBlue;
  static const Color navy = AppTheme.primaryBlue;
  static const Color lightPanel = AppTheme.lightPanel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: NfCard(
        onTap: onTap,
        onLongPress: onLongPress,
        radius: radius,
        backgroundColor: Colors.white,
        border: Border.all(
          color: navy.withOpacity(borderOpacity),
          width: borderWidth,
        ),
        shadows: AppTheme.cardShadow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: headerHeight,
              decoration: BoxDecoration(
                color: lightPanel,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radius),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                CategoryUtils.getIcon(postedItem.category),
                size: iconSize,
                color: darkBlue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status chip at the top
                  _StatusChip(
                    status: postedItem.status,
                    itemType: postedItem.type,
                    fontSize: chipFontSize,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    postedItem.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: darkBlue,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: navy),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          postedItem.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.caption.copyWith(
                            color: AppTheme.darkText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: navy),
                      const SizedBox(width: 4),
                      Text(
                        DateFormatter.formatRelativeDate(postedItem.createdAt),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
    required this.itemType,
    this.fontSize = 10,
  });
  final ItemStatus status;
  final ItemType itemType;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status, itemType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusInfo.icon, size: fontSize + 2, color: statusInfo.color),
          const SizedBox(width: 4),
          Text(
            statusInfo.label,
            style: TextStyle(
              color: statusInfo.color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  StatusInfo _getStatusInfo(ItemStatus status, ItemType itemType) {
    final isLost = itemType == ItemType.lost;

    switch (status) {
      case ItemStatus.returned:
        return StatusInfo(
          label: 'RETURNED',
          icon: Icons.check_circle,
          color: AppTheme.successGreen,
        );
      case ItemStatus.matched:
        return StatusInfo(
          label: 'POTENTIAL MATCH',
          icon: Icons.search,
          color: AppTheme.primaryBlue,
        );
      case ItemStatus.open:
        return StatusInfo(
          label: isLost ? 'SEARCHING' : 'AVAILABLE',
          icon: isLost ? Icons.search : Icons.notifications_active,
          color: isLost ? AppTheme.warningOrange : AppTheme.primaryBlue,
        );
      case ItemStatus.unclaimed:
        return StatusInfo(
          label: 'NOT CLAIMED',
          icon: Icons.cancel_outlined,
          color: AppTheme.errorRed,
        );
      case ItemStatus.closed:
        return StatusInfo(
          label: 'EXPIRED',
          icon: Icons.access_time,
          color: AppTheme.textGray,
        );
    }
  }
}

class StatusInfo {
  final String label;
  final IconData icon;
  final Color color;

  StatusInfo({required this.label, required this.icon, required this.color});
}
