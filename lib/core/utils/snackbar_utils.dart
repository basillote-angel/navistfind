import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

class SnackbarUtils {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      AppTheme.successGreen,
      leading: const Icon(Icons.check_circle, color: Colors.white),
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      AppTheme.errorRed,
      leading: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  static void showItemDeleted(BuildContext context) {
    showSuccess(context, 'Item deleted successfully');
  }

  static void _show(
    BuildContext context,
    String message,
    Color bg, {
    Widget? leading,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 8)],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
