import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

/// Centralized category utilities
/// Handles conversion between enum and string, and icon mapping
class CategoryUtils {
  /// Converts ItemCategory enum to string (as stored in backend)
  static String enumToString(ItemCategory category) {
    return category.label;
  }

  /// Converts string category name to ItemCategory enum
  /// Returns null if not found
  static ItemCategory? stringToEnum(String categoryName) {
    final normalized = categoryName.toLowerCase().trim();

    // Map backend category names to enum
    switch (normalized) {
      case 'electronics':
        return ItemCategory.electronics;
      case 'documents':
        return ItemCategory.documents;
      case 'accessories':
        return ItemCategory.accessories;
      case 'id and cards':
      case 'id or cards':
        return ItemCategory.idOrCards;
      case 'clothing':
        return ItemCategory.clothing;
      case 'bag and pouches':
      case 'bag or pouches':
        return ItemCategory.bagOrPouches;
      case 'personal item':
      case 'personal items':
        return ItemCategory.personalItems;
      case 'school supplies':
        return ItemCategory.schoolSupplies;
      case 'others types':
      case 'others':
      case 'other':
        return ItemCategory.others;
      default:
        return null;
    }
  }

  /// Gets icon for category - works with both enum and string
  /// This is the SINGLE SOURCE OF TRUTH for category icons
  static IconData getIcon(dynamic category) {
    ItemCategory? enumCategory;

    if (category is ItemCategory) {
      enumCategory = category;
    } else if (category is String) {
      enumCategory = stringToEnum(category);
    }

    if (enumCategory == null) {
      return Icons.inventory_2; // Default icon
    }

    switch (enumCategory) {
      case ItemCategory.electronics:
        return Icons.devices_other;
      case ItemCategory.documents:
        return Icons.description;
      case ItemCategory.accessories:
        return Icons.watch;
      case ItemCategory.idOrCards:
        return Icons.badge;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.bagOrPouches:
        return Icons.backpack;
      case ItemCategory.personalItems:
        return Icons.assignment_ind;
      case ItemCategory.schoolSupplies:
        return Icons.library_books;
      case ItemCategory.others:
        return Icons.category;
    }
  }
}

