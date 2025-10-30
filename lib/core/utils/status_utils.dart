import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';

IconData getStatusIconFromString(String status) {
  switch (status.toLowerCase()) {
    case 'returned':
    case 'claimed':
      return Icons.check_circle;
    case 'matched':
      return Icons.search;
    case 'open':
    case 'unclaimed':
      return Icons.search_off;
    case 'closed':
      return Icons.close;
    default:
      return Icons.inventory_2;
  }
}

Color getStatusColorFromString(String status) {
  switch (status.toLowerCase()) {
    case 'returned':
    case 'claimed':
      return AppTheme.successGreen;
    case 'matched':
      return AppTheme.primaryBlue;
    case 'open':
    case 'unclaimed':
      return AppTheme.errorRed;
    case 'closed':
      return AppTheme.textGray;
    default:
      return AppTheme.primaryBlue;
  }
}

String getUserFriendlyStatusLabelFromString(String status) {
  switch (status.toLowerCase()) {
    case 'returned':
    case 'claimed':
      return 'RETURNED';
    case 'matched':
      return 'POTENTIAL MATCHES';
    case 'open':
      return 'ACTIVE SEARCHES';
    case 'unclaimed':
      return 'NOT CLAIMED';
    case 'closed':
      return 'EXPIRED';
    default:
      return status.toUpperCase();
  }
}
