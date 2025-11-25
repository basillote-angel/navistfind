import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/lost_found/post-item/domain/models/category_model.dart';
import 'package:dio/dio.dart';

/// Service to fetch categories from the backend API
class CategoryService {
  static List<CategoryModel>? _cachedCategories;
  static DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Fetch categories from the API
  /// Returns cached categories if available and not expired
  static Future<List<CategoryModel>> getCategories({
    bool forceRefresh = false,
  }) async {
    // Return cached categories if available and not expired
    if (!forceRefresh &&
        _cachedCategories != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration) {
      return _cachedCategories!;
    }

    try {
      final response = await ApiClient.client.get('/api/categories');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic>? categoryList;

        // Handle different response formats
        if (data is List) {
          categoryList = data;
        } else if (data is Map && data['data'] is List) {
          categoryList = data['data'] as List;
        } else if (data is Map &&
            data['data'] is Map &&
            (data['data'] as Map)['data'] is List) {
          categoryList = (data['data'] as Map)['data'] as List;
        }

        if (categoryList != null) {
          _cachedCategories = categoryList
              .map(
                (item) => CategoryModel.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item),
                ),
              )
              .toList();
          _lastFetchTime = DateTime.now();
          return _cachedCategories!;
        }
      }

      // If we have cached categories, return them even if API call failed
      if (_cachedCategories != null) {
        return _cachedCategories!;
      }

      throw Exception('Failed to fetch categories: Invalid response format');
    } catch (e) {
      // If we have cached categories, return them even if API call failed
      if (_cachedCategories != null) {
        return _cachedCategories!;
      }

      if (e is DioException) {
        throw Exception('Failed to fetch categories: ${e.message}');
      }
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Get a category by ID
  static Future<CategoryModel?> getCategoryById(int id) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get a category by name (case-insensitive)
  static Future<CategoryModel?> getCategoryByName(String name) async {
    final categories = await getCategories();
    final normalizedName = name.toLowerCase().trim();
    try {
      return categories.firstWhere(
        (cat) => cat.name.toLowerCase().trim() == normalizedName,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear the cache
  static void clearCache() {
    _cachedCategories = null;
    _lastFetchTime = null;
  }
}

