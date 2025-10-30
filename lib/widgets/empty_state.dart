import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.buttonLabel,
    this.onButtonPressed,
    this.padding = const EdgeInsets.all(AppTheme.spacingXL),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonPressed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: AppTheme.lightPanel,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: Icon(icon, size: 64, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(title, style: AppTheme.heading4, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              subtitle,
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              const SizedBox(height: AppTheme.spacingXL),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_circle_outline),
                label: Text(buttonLabel!),
                style: AppTheme.getPrimaryButtonStyle(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
