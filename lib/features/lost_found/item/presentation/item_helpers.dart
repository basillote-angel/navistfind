import 'package:flutter/material.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

IconData getCategoryIcon(ItemCategory category) {
  switch (category) {
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
  
