import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class LoadingSectionHeaderPlaceholder extends StatelessWidget {
  const LoadingSectionHeaderPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Expanded(
          child: Container(
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingS),
        Container(
          width: 30,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class LoadingHorizontalCardsPlaceholder extends StatelessWidget {
  const LoadingHorizontalCardsPlaceholder({
    super.key,
    this.cardWidth = 190,
    this.cardHeight = 240,
    this.itemCount = 3,
    this.gap = 12,
  });

  final double cardWidth;
  final double cardHeight;
  final int itemCount;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemCount: itemCount,
        itemBuilder: (_, __) =>
            _CardPlaceholder(width: cardWidth, height: cardHeight),
      ),
    );
  }
}

class _CardPlaceholder extends StatelessWidget {
  const _CardPlaceholder({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: AppTheme.getCardDecoration(
        borderRadius: AppTheme.radiusLarge,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 20,
              width: 60,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            Container(
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 18,
              width: 140,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Container(
              height: 14,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 160,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 14,
              width: 100,
              decoration: BoxDecoration(
                color: AppTheme.lightGray,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
