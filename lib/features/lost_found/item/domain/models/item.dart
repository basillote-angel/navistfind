import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';
import 'package:navistfind/features/lost_found/post-item/domain/category_id_mapping.dart';

class Item {
  final int id;
  final int? ownerId;
  final int? finderId;
  final int? posterId; // user_id

  // unified/new
  final String title;
  final int? categoryId;
  final String? categoryName;
  final String description;
  final ItemStatus status;
  final ItemType type;
  final String location;
  final String date;
  final String createdAt;
  final String updatedAt;

  // derived for UI
  final ItemCategory category;

  // optional relations
  final User? owner;
  final User? finder;

  Item({
    required this.id,
    this.ownerId,
    this.finderId,
    this.posterId,
    required this.title,
    this.categoryId,
    this.categoryName,
    required this.description,
    required this.status,
    required this.type,
    required this.location,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.owner,
    this.finder,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? '').toString();
    final categoryId = json['category_id'] is int
        ? json['category_id'] as int
        : null;
    final categoryName =
        json['category_name']?.toString() ?? json['category']?.toString();
    final date =
        (json['date'] ??
                json['date_lost'] ??
                json['date_found'] ??
                json['lost_found_date'] ??
                '')
            .toString();
    final createdAt = (json['createdAt'] ?? json['created_at'] ?? '')
        .toString();
    final updatedAt = (json['updatedAt'] ?? json['updated_at'] ?? '')
        .toString();
    final ownerId = json['owner_id'] is int ? json['owner_id'] as int : null;
    final finderId = json['finder_id'] is int ? json['finder_id'] as int : null;
    final itemCategory = _deriveCategory(categoryId, categoryName);

    // Infer type if backend didn't include it (type-specific queries)
    final rawType = (json['type'] ?? '').toString();
    final inferredType = rawType.isNotEmpty
        ? rawType
        : (json.containsKey('date_found') ? 'found' : 'lost');

    // Ensure id is present and is an int
    final itemId = json['id'];
    if (itemId == null || itemId is! int) {
      throw FormatException(
        'Item.fromJson: missing or invalid id field. Received: $itemId',
      );
    }

    return Item(
      id: itemId,
      ownerId: ownerId,
      finderId: finderId,
      posterId: (json['user_id'] is int) ? json['user_id'] as int : null,
      title: title,
      categoryId: categoryId,
      categoryName: categoryName,
      description: json['description'] ?? '',
      status: ItemStatusExtension.fromString((json['status'] ?? '').toString()),
      type: ItemTypeExtension.fromString(inferredType),
      location: json['location'] ?? '',
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      category: itemCategory,
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

// back-compat getters
extension ItemBackCompat on Item {
  String get name => title;
  String get lost_found_date => date;
  String get created_at => createdAt;
  String get updated_at => updatedAt;
  int? get owner_id => ownerId;
  int? get finder_id => finderId;
}

ItemCategory _deriveCategory(int? categoryId, String? categoryName) {
  if (categoryName != null && categoryName.isNotEmpty) {
    try {
      return ItemCategoryExtension.fromString(categoryName);
    } catch (_) {}
  }
  final byId = categoryEnumFromId(categoryId);
  if (byId != null) return byId;
  return ItemCategory.others;
}
