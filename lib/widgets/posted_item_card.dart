import 'package:flutter/material.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/widgets/nf_card.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/core/utils/date_formatter.dart';
import 'package:navistfind/widgets/status_chip.dart';

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
                  StatusChip(
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
