import 'package:flutter/material.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

/// Get category icon - delegates to centralized CategoryUtils
/// Maintains backward compatibility for existing imports
IconData getCategoryIcon(ItemCategory category) {
  return CategoryUtils.getIcon(category);
}
