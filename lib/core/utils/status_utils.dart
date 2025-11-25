import 'package:flutter/material.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';

IconData getStatusIconFromString(String status) {
  final ItemStatus parsed = ItemStatusExtension.safeValue(status);
  switch (parsed) {
    case ItemStatus.lostReported:
      return Icons.report_problem_outlined;
    case ItemStatus.resolved:
      return Icons.verified_outlined;
    case ItemStatus.foundUnclaimed:
      return Icons.inventory_2_outlined;
    case ItemStatus.claimPending:
      return Icons.hourglass_top_rounded;
    case ItemStatus.claimApproved:
      return Icons.assignment_turned_in_outlined;
    case ItemStatus.collected:
      return Icons.inventory_outlined;
  }
}

Color getStatusColorFromString(String status) {
  final ItemStatus parsed = ItemStatusExtension.safeValue(status);
  switch (parsed) {
    case ItemStatus.lostReported:
      return AppTheme.warningOrange;
    case ItemStatus.resolved:
      return AppTheme.successGreen;
    case ItemStatus.foundUnclaimed:
      return AppTheme.primaryBlue;
    case ItemStatus.claimPending:
      return AppTheme.warningOrange;
    case ItemStatus.claimApproved:
      return AppTheme.successGreen;
    case ItemStatus.collected:
      return AppTheme.textGray;
  }
}

String getUserFriendlyStatusLabelFromString(String status) {
  final ItemStatus parsed = ItemStatusExtension.safeValue(status);
  return parsed.displayLabel;
}
