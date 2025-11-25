import 'package:flutter/material.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

IconData getCategoryIcon(ItemCategory category) {
  return CategoryUtils.getIcon(category);
}

bool canModifyItem(ItemStatus status, ItemType type) {
  if (type == ItemType.lost) return status == ItemStatus.lostReported;
  return status == ItemStatus.foundUnclaimed;
}

String editDisabledReason(ItemStatus status, ItemType type) {
  if (canModifyItem(status, type)) return '';

  final bool isLost = type == ItemType.lost;
  switch (status) {
    case ItemStatus.resolved:
      return isLost
          ? 'This lost report is already resolved.'
          : 'This found item is already resolved.';
    case ItemStatus.claimPending:
      return isLost
          ? 'A claim review is already in progress.'
          : 'A claimant is awaiting admin review.';
    case ItemStatus.claimApproved:
      return 'Claim already approved — contact an admin for updates.';
    case ItemStatus.collected:
      return 'This item has already been collected.';
    case ItemStatus.lostReported:
    case ItemStatus.foundUnclaimed:
      return '';
  }
}

String deleteDisabledReason(ItemStatus status, ItemType type) {
  if (canModifyItem(status, type)) return '';

  switch (status) {
    case ItemStatus.resolved:
      return 'Cannot delete a resolved record.';
    case ItemStatus.claimPending:
      return 'Cannot delete while a claim is pending review.';
    case ItemStatus.claimApproved:
      return 'Cannot delete while pickup is pending.';
    case ItemStatus.collected:
      return 'Cannot delete a collected record.';
    case ItemStatus.lostReported:
    case ItemStatus.foundUnclaimed:
      return '';
  }
}

bool includeInLostList(ItemStatus status) {
  return status == ItemStatus.lostReported || status == ItemStatus.resolved;
}

bool includeInFoundList(ItemStatus status) {
  return status == ItemStatus.foundUnclaimed ||
      status == ItemStatus.claimPending;
}

bool showCompetitionIndicator(ItemStatus status) {
  return status == ItemStatus.claimPending;
}

String statusDisplayLabel(ItemStatus status) {
  return status.displayLabel;
}
