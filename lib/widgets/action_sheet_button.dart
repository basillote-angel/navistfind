import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class ActionSheetButton extends StatelessWidget {
  const ActionSheetButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    required this.enabled,
    this.disabledReason,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: enabled ? color : AppTheme.textGray, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTheme.bodyMedium.copyWith(
                      color: enabled ? color : AppTheme.textGray,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (disabledReason != null && !enabled) ...[
                    const SizedBox(height: 2),
                    Text(
                      disabledReason!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textGray,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!enabled)
              Icon(
                Icons.info_outline,
                size: 18,
                color: AppTheme.textGray.withOpacity(0.5),
              ),
          ],
        ),
      ),
    );
  }
}
