import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/data/category_service.dart';

/// Fallback mapping between ItemCategory enum and backend categories.id
/// Used only when API is unavailable or category name matching fails
const Map<ItemCategory, int> _fallbackCategoryToId = {
  ItemCategory.electronics: 1,
  ItemCategory.documents: 2,
  ItemCategory.accessories: 3,
  ItemCategory.idOrCards: 4,
  ItemCategory.clothing: 5,
  ItemCategory.bagOrPouches: 6,
  ItemCategory.personalItems: 7,
  ItemCategory.schoolSupplies: 8,
  ItemCategory.others: 9,
};

/// Dynamic mapping from API - updated when categories are fetched
final Map<ItemCategory, int> _dynamicCategoryIds = {};

/// Synchronous fallback - use async version for better accuracy
int? categoryIdFromEnum(ItemCategory category) =>
    _dynamicCategoryIds[category] ?? _fallbackCategoryToId[category];

/// Reverse mapping id -> enum for deriving UI category from payloads
final Map<int, ItemCategory> _idToCategory = {
  for (final entry in _fallbackCategoryToId.entries) entry.value: entry.key,
};

ItemCategory? categoryEnumFromId(int? id) {
  if (id == null) return null;
  // Check dynamic mapping first (updated from API or registered mappings), then fallback
  // The _idToCategory map is updated both by _ensureCategoryCacheLoaded and registerCategoryMapping
  return _idToCategory[id];
}

// ────────────────────────────────────────────────────────────────────────────
// Dynamic resolver (fetch from backend to avoid hardcoded ID mismatches)
// ────────────────────────────────────────────────────────────────────────────

String _normalize(String value) => value.toLowerCase().replaceAll(
  RegExp(r'[^a-z0-9]'),
  '',
); // strip spaces/symbols

/// Load categories from API and update mappings
Future<void> _ensureCategoryCacheLoaded() async {
  try {
    final categories = await CategoryService.getCategories();

    // Clear previous dynamic mappings
    _dynamicCategoryIds.clear();

    // Build name to ID cache for quick lookup
    final Map<String, int> nameToIdMap = {};
    for (final category in categories) {
      final normalizedName = _normalize(category.name);
      nameToIdMap[normalizedName] = category.id;
      // Don't set default here - only set after matching attempt
    }

    // Map each enum category to its corresponding API category ID
    for (final categoryEnum in ItemCategory.values) {
      // Try multiple name variations for robust matching
      final candidates = <String>{
        _normalize(categoryEnum.label),
        _normalize(categoryEnum.apiValue),
        _normalize(categoryEnum.label.replaceAll('&', 'and')),
        _normalize(categoryEnum.label.replaceAll('and', '&')),
        _normalize(categoryEnum.label.replaceAll(' ', '')),
      };

      // Find matching category from API
      int? matchedId;
      for (final key in candidates) {
        matchedId = nameToIdMap[key];
        if (matchedId != null) {
          break;
        }
      }

      // Also try direct name matching from API categories
      if (matchedId == null) {
        for (final apiCategory in categories) {
          final apiNameNormalized = _normalize(apiCategory.name);
          if (candidates.contains(apiNameNormalized)) {
            matchedId = apiCategory.id;
            break;
          }
        }
      }

      if (matchedId != null) {
        _dynamicCategoryIds[categoryEnum] = matchedId;
        _idToCategory[matchedId] = categoryEnum;
      }
    }

    // For any API categories that weren't matched, try to parse by name
    // This handles cases where the API has categories not in our enum
    for (final apiCategory in categories) {
      if (!_idToCategory.containsKey(apiCategory.id)) {
        // Try to parse the category name to see if it matches any enum
        final parsedCategory = ItemCategoryExtension.tryParse(apiCategory.name);
        if (parsedCategory != null) {
          _idToCategory[apiCategory.id] = parsedCategory;
          _dynamicCategoryIds[parsedCategory] = apiCategory.id;
        } else {
          // If no match found, use others as fallback
          _idToCategory[apiCategory.id] = ItemCategory.others;
        }
      }
    }
  } catch (e) {
    // Log error but continue with fallback mapping
    // ignore: avoid_print
    print('Failed to load categories from API: $e');
  }
}

/// Get category ID from enum, fetching from API if needed
/// This is the preferred method as it ensures accurate category IDs
Future<int?> categoryIdFromEnumAsync(ItemCategory category) async {
  await _ensureCategoryCacheLoaded();

  // Return dynamic mapping if available (from API)
  if (_dynamicCategoryIds.containsKey(category)) {
    return _dynamicCategoryIds[category];
  }

  // Fallback to static map if API not available or category not found
  return _fallbackCategoryToId[category];
}

/// Register a category mapping (useful when receiving category info from API responses)
void registerCategoryMapping({ItemCategory? category, int? id, String? name}) {
  if (category != null && id != null) {
    _dynamicCategoryIds[category] = id;
    _idToCategory[id] = category;
  }

  // Clear cache to force refresh on next fetch
  if (id != null) {
    CategoryService.clearCache();
  }
}
