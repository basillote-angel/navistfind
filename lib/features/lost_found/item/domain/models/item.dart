import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';
import 'package:navistfind/features/lost_found/post-item/domain/category_id_mapping.dart';
import 'package:navistfind/core/constants.dart';

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

  // claim image fields
  final String? claimImage;
  final String? claimImageUrl;

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
    this.claimImage,
    this.claimImageUrl,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] ?? json['name'] ?? '').toString();
    int? categoryId = json['category_id'] is int
        ? json['category_id'] as int
        : int.tryParse('${json['category_id']}');
    String? categoryName = json['category_name']?.toString();
    final categoryRaw = json['category'];

    // Debug: Log raw category data from API
    if (categoryRaw != null || categoryName != null || categoryId != null) {
      print(
        '📦 Category data from API: category_id=$categoryId, category_name="$categoryName", category=$categoryRaw',
      );
    }

    if ((categoryName == null || categoryName.isEmpty) && categoryRaw != null) {
      if (categoryRaw is Map) {
        final map = Map<String, dynamic>.from(categoryRaw);
        categoryName = map['name']?.toString();
        categoryId ??= map['id'] is int
            ? map['id'] as int
            : int.tryParse('${map['id']}');
        print(
          '📦 Extracted from category object: id=$categoryId, name="$categoryName"',
        );
      } else if (categoryRaw is String) {
        categoryName = categoryRaw;
        print('📦 Category is string: "$categoryName"');
      }
    }
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
    // Priority: Use category name from API first (most accurate - matches database)
    // Then fall back to ID mapping if name not available
    // This ensures we display what's actually in the database
    ItemCategory itemCategory;

    if (categoryName != null && categoryName.isNotEmpty) {
      // First priority: Parse by name (matches what admin dashboard shows)
      final byName = ItemCategoryExtension.tryParse(categoryName);
      if (byName != null) {
        itemCategory = byName;
        print(
          '✅ Category resolved by name: "$categoryName" -> ${itemCategory.name}',
        );

        // Register/update the ID mapping for future use
        if (categoryId != null) {
          registerCategoryMapping(
            category: itemCategory,
            id: categoryId,
            name: categoryName,
          );
        }
      } else {
        // Name parsing failed, try ID as fallback
        if (categoryId != null) {
          final byId = categoryEnumFromId(categoryId);
          if (byId != null) {
            itemCategory = byId;
            print(
              '⚠️ Category name "$categoryName" failed to parse, using ID $categoryId -> ${itemCategory.name}',
            );
            // Register the name mapping for future use
            registerCategoryMapping(
              category: itemCategory,
              id: categoryId,
              name: categoryName,
            );
          } else {
            itemCategory = ItemCategory.others;
            print(
              '⚠️ Category name "$categoryName" and ID $categoryId both failed, using Others',
            );
          }
        } else {
          itemCategory = ItemCategory.others;
          print(
            '⚠️ Category name "$categoryName" parsing failed and no ID, using Others',
          );
        }
      }
    } else if (categoryId != null) {
      // No name available, use ID mapping
      final byId = categoryEnumFromId(categoryId);
      if (byId != null) {
        itemCategory = byId;
        print(
          '✅ Category resolved by ID only: $categoryId -> ${itemCategory.name}',
        );
      } else {
        itemCategory = ItemCategory.others;
        print(
          '⚠️ Category ID $categoryId not in mapping and no name, using Others',
        );
      }
    } else {
      itemCategory = ItemCategory.others;
      print('⚠️ No category_id or category_name provided, using Others');
    }
    if (categoryId != null) {
      registerCategoryMapping(
        category: itemCategory,
        id: categoryId,
        name: categoryName ?? itemCategory.label,
      );
    } else if (categoryName != null && categoryName.isNotEmpty) {
      registerCategoryMapping(category: itemCategory, name: categoryName);
    }

    // Infer type if backend didn't include it (type-specific queries)
    final rawType = (json['type'] ?? '').toString();
    final inferredType = rawType.isNotEmpty
        ? rawType
        : (json.containsKey('date_found') ? 'found' : 'lost');
    final itemType = ItemTypeExtension.fromString(inferredType);
    final rawStatus = json['status']?.toString();
    final statusValue = ItemStatusExtension.safeValue(
      rawStatus,
      fallback: itemType == ItemType.lost
          ? ItemStatus.lostReported
          : ItemStatus.foundUnclaimed,
    );

    // Debug logging to track status parsing issues
    if (rawStatus != null && rawStatus.isNotEmpty) {
      try {
        final parsedStatus = ItemStatusExtension.fromString(rawStatus);
        if (parsedStatus != statusValue) {
          print(
            '⚠️ Status parsing mismatch: Raw="$rawStatus", Parsed=${parsedStatus.name}, Fallback=${statusValue.name}',
          );
        }
      } catch (e) {
        print(
          '⚠️ Status parsing failed: Raw="$rawStatus", Error=$e, Using fallback=${statusValue.name}',
        );
      }
    }

    // Ensure id is present and is an int
    final itemIdRaw = json['id'];
    final int? itemId = itemIdRaw is int
        ? itemIdRaw
        : int.tryParse('$itemIdRaw');
    if (itemId == null) {
      throw FormatException(
        'Item.fromJson: missing or invalid id field. Received: $itemIdRaw',
      );
    }

    // Parse claim image from nested claim object or direct fields
    String? claimImage;
    String? claimImageUrl;

    if (json['claim'] is Map) {
      final claim = Map<String, dynamic>.from(json['claim'] as Map);
      claimImage = claim['claim_image']?.toString();
      claimImageUrl =
          claim['claim_image_url']?.toString() ??
          (claimImage != null
              ? '${Constants.backendBaseUrl}/storage/$claimImage'
              : null);
    } else if (json['claim_image'] != null) {
      claimImage = json['claim_image']?.toString();
      claimImageUrl =
          json['claim_image_url']?.toString() ??
          (claimImage != null
              ? '${Constants.backendBaseUrl}/storage/$claimImage'
              : null);
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
      status: statusValue,
      type: itemType,
      location: json['location'] ?? '',
      date: date,
      createdAt: createdAt,
      updatedAt: updatedAt,
      category: itemCategory,
      owner: json['owner'] != null ? User.fromJson(json['owner']) : null,
      finder: json['finder'] != null ? User.fromJson(json['finder']) : null,
      claimImage: claimImage,
      claimImageUrl: claimImageUrl,
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
  final LostItemInfo? lostItem; // NEW: Which lost item this matches

  MatchScoreItem({required this.item, required this.score, this.lostItem});

  factory MatchScoreItem.fromJson(Map<String, dynamic> json) {
    Item? parsedItem;
    if (json['item'] is Map<String, dynamic>) {
      parsedItem = Item.fromJson(json['item'] as Map<String, dynamic>);
    } else if (json['item'] is Map) {
      parsedItem = Item.fromJson(
        Map<String, dynamic>.from(json['item'] as Map),
      );
    }

    final rawScore = json['score'];
    final double score;
    if (rawScore is num) {
      score = rawScore.toDouble();
    } else if (rawScore is String) {
      score = double.tryParse(rawScore) ?? 0.0;
    } else {
      score = 0.0;
    }

    // Parse lost_item if present
    LostItemInfo? lostItem;
    if (json['lost_item'] is Map<String, dynamic>) {
      lostItem = LostItemInfo.fromJson(
        json['lost_item'] as Map<String, dynamic>,
      );
    } else if (json['lost_item'] is Map) {
      lostItem = LostItemInfo.fromJson(
        Map<String, dynamic>.from(json['lost_item'] as Map),
      );
    }

    return MatchScoreItem(item: parsedItem, score: score, lostItem: lostItem);
  }
}

// NEW: Lost item info model
class LostItemInfo {
  final int id;
  final String title;
  final int? categoryId;
  final String? categoryName;

  LostItemInfo({
    required this.id,
    required this.title,
    this.categoryId,
    this.categoryName,
  });

  factory LostItemInfo.fromJson(Map<String, dynamic> json) {
    return LostItemInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title']?.toString() ?? '',
      categoryId: json['category_id'] is int
          ? json['category_id']
          : (json['category_id'] != null
                ? int.tryParse(json['category_id'].toString())
                : null),
      categoryName: json['category_name']?.toString(),
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
