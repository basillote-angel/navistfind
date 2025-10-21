import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

class PostedItem {
  final int id;
  final int? ownerId;
  final int? finderId;
  final String name;
  final String category;
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
      name: json['name'],
      category: json['category'],
      description: json['description'],
      ownerId: json['owner_id'],
      finderId: json['finder_id'],
      status: ItemStatusExtension.fromString(json['status']),
      type: ItemTypeExtension.fromString(json['type']),
      location: json['location'],
      lostFoundDate: json['lost_found_date'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
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
