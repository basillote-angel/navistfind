import 'package:navistfind/features/item/domain/enums/item_status.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';

class Item {
  final int id;
  final int? owner_id;
  final int? finder_id;
  final String name;
  final ItemCategory category;
  final String description;
  final ItemStatus status;
  final ItemType type;
  final String location;
  final String lost_found_date;
  final String created_at;
  final String updated_at;
  final User? owner;
  final User? finder;

  Item({
    required this.id,
    this.owner_id,
    this.finder_id,
    required this.name,
    required this.category,
    required this.description,
    required this.status,
    required this.type,
    required this.location,
    required this.lost_found_date,
    required this.created_at,
    required this.updated_at,
    this.owner,
    this.finder,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      owner_id: json['owner_id'],
      finder_id: json['finder_id'],
      status: ItemStatusExtension.fromString(json['status']),
      type:  ItemTypeExtension.fromString(json['type']),
      category:  ItemCategoryExtension.fromString(json['category']),
      location: json['location'],
      lost_found_date: json['lost_found_date'],
      created_at: json['created_at'],
      updated_at: json['updated_at'],
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      finder: json['finder'] != null ? User.fromJson(json['finder']) : null,
    );
  }
}

class BestMatchedItem {
  final MatchScoreItem? highestBest;
  final MatchScoreItem? lowerBest;

  BestMatchedItem({this.highestBest, this.lowerBest});

  factory BestMatchedItem.fromJson(Map<String, dynamic> json) {
    return BestMatchedItem(
      highestBest: json['highest_best'] != null
          ? MatchScoreItem.fromJson(json['highest_best'])
          : null,
      lowerBest: json['lower_best'] != null
          ? MatchScoreItem.fromJson(json['lower_best'])
          : null,
    );
  }
}

class MatchScoreItem {
  final Item? item;
  final double score;

  MatchScoreItem({required this.item, required this.score});

  factory MatchScoreItem.fromJson(Map<String, dynamic> json) {
    return MatchScoreItem(
      item: json['item'] != null ? Item.fromJson(json['item']) : null,
      score: (json['score'] != null ? (json['score'] as num).toDouble() : 0.0),
    );
  }
}
