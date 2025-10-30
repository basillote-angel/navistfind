import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class StatusHeader extends StatelessWidget {
  const StatusHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Text(label, style: AppTheme.heading4.copyWith(fontSize: 17)),
              const SizedBox(width: AppTheme.spacingM),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Text(
                  '$count',
                  style: AppTheme.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        ],
      ),
    );
  }
}
