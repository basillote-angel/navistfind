import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(
            icon ?? Icons.info_outline,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            title,
            style: AppTheme.heading3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
