import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/post-item/domain/category_id_mapping.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

class PostedItem {
  final int id;
  final int? ownerId;
  final int? finderId;
  final String name;
  final String category;
  final int? categoryId;
  final String? categoryName;
  final String description;
  final ItemStatus status;
  final ItemType type;
  final String location;
  final String lostFoundDate;
  final String createdAt;
  final String updatedAt;
  final BestMatchedItem matchedItem;

  PostedItem({
    required this.id,
    this.ownerId,
    this.finderId,
    required this.name,
    required this.category,
    this.categoryId,
    this.categoryName,
    required this.description,
    required this.status,
    required this.type,
    required this.location,
    required this.lostFoundDate,
    required this.createdAt,
    required this.updatedAt,
    required this.matchedItem,
  });

  factory PostedItem.fromJson(Map<String, dynamic> json) {
    final itemType = ItemTypeExtension.fromString(
      (json['type'] ?? '').toString(),
    );
    final statusValue = ItemStatusExtension.safeValue(
      json['status']?.toString(),
      fallback: itemType == ItemType.lost
          ? ItemStatus.lostReported
          : ItemStatus.foundUnclaimed,
    );

    int? categoryId = json['category_id'] is int
        ? json['category_id'] as int
        : null;
    String? categoryName = json['category_name']?.toString();
    final categoryRaw = json['category'];
    if ((categoryName == null || categoryName.isEmpty) && categoryRaw != null) {
      if (categoryRaw is Map) {
        final map = Map<String, dynamic>.from(categoryRaw);
        categoryName = map['name']?.toString();
        categoryId ??= map['id'] is int
            ? map['id'] as int
            : int.tryParse('${map['id']}');
      } else if (categoryRaw is String) {
        categoryName = categoryRaw;
      }
    }

    ItemCategory? resolvedCategory;
    if (categoryName != null && categoryName.isNotEmpty) {
      try {
        resolvedCategory = ItemCategoryExtension.fromString(categoryName);
      } catch (_) {}
    }
    resolvedCategory ??= categoryEnumFromId(categoryId);

    registerCategoryMapping(
      category: resolvedCategory ?? ItemCategory.others,
      id: categoryId,
      name: categoryName ?? resolvedCategory?.label,
    );

    return PostedItem(
      id: json['id'],
      name: (json['title'] ?? json['name'] ?? '').toString(),
      category: resolvedCategory?.label ?? (categoryName ?? 'Others'),
      categoryId: categoryId,
      categoryName: categoryName ?? resolvedCategory?.label,
      description: json['description'] ?? '',
      ownerId: json['owner_id'],
      finderId: json['finder_id'],
      status: statusValue,
      type: itemType,
      location: json['location'] ?? '',
      lostFoundDate:
          (json['date'] ??
                  json['date_lost'] ??
                  json['date_found'] ??
                  json['lost_found_date'] ??
                  '')
              .toString(),
      createdAt: (json['createdAt'] ?? json['created_at'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
      matchedItem: _parseMatchedItem(json),
    );
  }
}

BestMatchedItem _parseMatchedItem(Map<String, dynamic> json) {
  final dynamic v = json['matchedItem'] ?? json['matched_item'];
  if (v is Map<String, dynamic>) {
    return BestMatchedItem.fromJson(v);
  }
  if (v is Map) {
    return BestMatchedItem.fromJson(Map<String, dynamic>.from(v));
  }
  return BestMatchedItem();
}
