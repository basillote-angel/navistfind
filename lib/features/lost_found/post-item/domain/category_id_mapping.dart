import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/core/network/api_client.dart';
import 'package:dio/dio.dart';

/// Temporary mapping between ItemCategory enum and backend categories.id
/// Replace IDs to match your database or switch to fetching from /api/categories.
const Map<ItemCategory, int> _categoryToId = {
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

int? categoryIdFromEnum(ItemCategory category) => _categoryToId[category];

/// Reverse mapping id -> enum for deriving UI category from payloads
final Map<int, ItemCategory> _idToCategory = {
  for (final entry in _categoryToId.entries) entry.value: entry.key,
};

ItemCategory? categoryEnumFromId(int? id) {
  if (id == null) return null;
  return _idToCategory[id];
}

// ────────────────────────────────────────────────────────────────────────────
// Dynamic resolver (fetch from backend to avoid hardcoded ID mismatches)
// ────────────────────────────────────────────────────────────────────────────

Map<String, int>? _nameToIdCache; // normalizedName -> id
DateTime? _lastLoadedAt;

String _normalize(String value) => value.toLowerCase().replaceAll(
  RegExp(r'[^a-z0-9]'),
  '',
); // strip spaces/symbols

Future<void> _ensureCategoryCacheLoaded() async {
  // Refresh cache at most every 10 minutes
  if (_nameToIdCache != null &&
      _lastLoadedAt != null &&
      DateTime.now().difference(_lastLoadedAt!).inMinutes < 10) {
    return;
  }
  try {
    final response = await ApiClient.client.get('/api/categories');
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is List) {
        final Map<String, int> map = {};
        for (final item in data) {
          if (item is Map && item['id'] != null && item['name'] != null) {
            final id = item['id'];
            final name = item['name'].toString();
            final norm = _normalize(name);
            if (id is int) map[norm] = id;
            // also store common alternates (e.g., idsandcards vs idandcards)
          }
        }
        _nameToIdCache = map;
        _lastLoadedAt = DateTime.now();
      }
    }
  } catch (e) {
    if (e is DioException) {
      // Log and proceed with fallback mapping
      // ignore: avoid_print
      print('GET /api/categories failed: status=${e.response?.statusCode}');
    }
  }
}

Future<int?> categoryIdFromEnumAsync(ItemCategory category) async {
  await _ensureCategoryCacheLoaded();
  if (_nameToIdCache != null && _nameToIdCache!.isNotEmpty) {
    // Try multiple keys for robustness
    final keysToTry = <String>{
      _normalize(category.label),
      _normalize(category.apiValue),
      _normalize(category.label.replaceAll('&', 'and')),
      _normalize(category.label.replaceAll('and', '&')),
    };
    for (final key in keysToTry) {
      final id = _nameToIdCache![key];
      if (id != null) return id;
    }
  }
  // Fallback to static map if API not available or name not found
  return categoryIdFromEnum(category);
}
