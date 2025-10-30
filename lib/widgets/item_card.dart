import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/widgets/nf_card.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/core/utils/date_formatter.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.cardWidth = 180,
    this.headerHeight = 110,
    this.radius = 30,
    this.borderOpacity = 0.04,
    this.borderWidth = 0.5,
    this.iconSize = 42,
    this.titleFontSize = 15,
    this.chipFontSize = 10,
  });

  final Item item;
  final VoidCallback onTap;
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
                CategoryUtils.getIcon(item.category),
                size: iconSize,
                color: darkBlue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: darkBlue,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TypeChip(type: item.type, fontSize: chipFontSize),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: navy),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
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
                        DateFormatter.formatRelativeDate(item.date),
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type, this.fontSize = 10});
  final ItemType type;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bool isLost = type == ItemType.lost;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isLost
            ? AppTheme.errorRed.withOpacity(0.1)
            : AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Text(
        isLost ? 'Lost' : 'Found',
        style: TextStyle(
          color: isLost ? AppTheme.errorRed : AppTheme.primaryBlue,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
