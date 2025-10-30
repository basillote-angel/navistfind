import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
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
    return PostedItem(
      id: json['id'],
      name: (json['title'] ?? json['name'] ?? '').toString(),
      category: (json['category_name'] ?? json['category'] ?? '').toString(),
      categoryId: json['category_id'],
      categoryName: (json['category_name'] ?? json['category'])?.toString(),
      description: json['description'] ?? '',
      ownerId: json['owner_id'],
      finderId: json['finder_id'],
      status: ItemStatusExtension.fromString((json['status'] ?? '').toString()),
      type: ItemTypeExtension.fromString((json['type'] ?? '').toString()),
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
