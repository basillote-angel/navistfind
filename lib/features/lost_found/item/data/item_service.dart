import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/core/utils/date_formatter.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/domain/category_id_mapping.dart';
import 'dart:io';

class ItemService {
  Future<List<Item>> fetchItems() async {
    try {
      final response = await ApiClient.client.get('/api/items');

      final status = response.statusCode ?? 500;
      if (status == 200) {
        final body = response.data;
        if (body is List) {
          return body.map((j) => Item.fromJson(j)).toList();
        }
        if (body is Map && body['data'] is List) {
          final list = body['data'] as List;
          return list.map((j) => Item.fromJson(j)).toList();
        }
        return <Item>[]; // unexpected format but not an error
      }
      if (status == 204 || status == 404) {
        return <Item>[];
      }
      throw Exception('Failed to load items (status: $status)');
    } catch (e) {
      if (e is DioException) {
        print(
          'GET /api/items failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<Item> fetchItemDetails(int id, {ItemType? type}) async {
    try {
      final response = await ApiClient.client.get(
        '/api/items/$id',
        queryParameters: {if (type != null) 'type': type.name},
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        Map<String, dynamic>? payload;
        if (raw is Map<String, dynamic>) {
          if (raw['data'] is Map) {
            payload = Map<String, dynamic>.from(raw['data'] as Map);
          } else {
            payload = raw;
          }
        } else if (raw is Map) {
          payload = Map<String, dynamic>.from(raw);
        }
        if (payload != null) {
          return Item.fromJson(payload);
        }
        throw const FormatException('Invalid item response shape.');
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      if (e is DioException) {
        print(
          'GET /api/items/$id failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<MatchScoreItem>> fetchMatchesItems(int id) async {
    try {
      final response = await ApiClient.client.get('/api/items/$id/matches');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => MatchScoreItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      if (e is DioException) {
        print(
          'GET /api/items/$id/matches failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<MatchScoreItem>> fetchRecommendedItems() async {
    try {
      final response = await ApiClient.client.get('/api/items/recommended');
      final status = response.statusCode ?? 500;

      if (status == 200) {
        final body = response.data;
        List<dynamic>? resultList;

        // Support new format (with 'flat' key) and old formats
        if (body is Map && body['flat'] is List) {
          // New format: { "flat": [...], "grouped": [...] }
          resultList = body['flat'] as List;
        } else if (body is List) {
          // Old format: direct list
          resultList = body;
        } else if (body is Map && body['data'] is List) {
          // Alternative format: nested in 'data' key
          resultList = body['data'] as List;
        }

        if (resultList == null) return <MatchScoreItem>[];

        // Parse all items first (like recommendations_screen does)
        // This ensures we don't lose valid items due to structure differences
        final parsedItems = resultList
            .map((item) {
              try {
                return MatchScoreItem.fromJson(
                  item is Map<String, dynamic>
                      ? item
                      : Map<String, dynamic>.from(item as Map),
                );
              } catch (e) {
                // Log parsing errors but don't fail completely
                print('Failed to parse recommendation item: $e');
                return null;
              }
            })
            .whereType<MatchScoreItem>()
            .toList();

        // Filter to include only FOUND_UNCLAIMED and CLAIM_PENDING items
        // (CLAIM_APPROVED and COLLECTED items should not appear in recommendations)
        return parsedItems.where((match) {
          // Keep items that are null (will be filtered out by whereType above)
          if (match.item == null) return false;

          // Filter by status - only show unclaimed or pending items
          final status = match.item!.status;
          return status == ItemStatus.foundUnclaimed ||
              status == ItemStatus.claimPending;
        }).toList();
      }

      if (status == 204 || status == 404) {
        return <MatchScoreItem>[];
      }

      throw Exception('Failed to load recommended items (status: $status)');
    } catch (e) {
      if (e is DioException) {
        print(
          'GET /api/items/recommended failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<Item>> fetchItemsFiltered({
    String? query,
    ItemType? type,
    ItemCategory? category,
    DateTime? dateFrom,
    DateTime? dateTo,
    String sort = 'newest',
  }) async {
    try {
      final params = <String, dynamic>{};

      if (query != null && query.trim().isNotEmpty) {
        params['query'] = query.trim();
      }
      if (type != null) params['type'] = type.name;
      if (category != null) {
        // Use async version to ensure accurate category ID from API
        final id = await categoryIdFromEnumAsync(category);
        if (id != null) params['category'] = id;
      }
      if (dateFrom != null) {
        params['dateFrom'] = DateFormatter.formatDateForApi(dateFrom);
      }
      if (dateTo != null) {
        params['dateTo'] = DateFormatter.formatDateForApi(dateTo);
      }
      params['sort'] = sort;

      final response = await ApiClient.client.get(
        '/api/items',
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is List) {
          return body.map((j) => Item.fromJson(j)).toList();
        }
        if (body is Map && body['data'] is List) {
          final list = body['data'] as List;
          return list.map((j) => Item.fromJson(j)).toList();
        }
        return <Item>[];
      } else {
        throw Exception('Failed to load filtered items');
      }
    } catch (e) {
      if (e is DioException) {
        print(
          'GET /api/items with filters failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<Item> claimFoundItem({
    required int id,
    required String message,
    required String contactName,
    required String email,
    required String phoneNumber,
    File? imageFile,
  }) async {
    try {
      // If image is provided, use multipart form data
      if (imageFile != null) {
        final formData = FormData.fromMap({
          'message': message,
          'contactName': contactName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
          'image': await MultipartFile.fromFile(
            imageFile.path,
            filename: imageFile.path.split('/').last,
          ),
        });

        final response = await ApiClient.client.post(
          '/api/items/$id/claim',
          data: formData,
        );
        if (response.statusCode == 200) {
          final itemPayload = _extractItemPayload(response.data);
          if (itemPayload != null) {
            return Item.fromJson(itemPayload);
          }
          throw const FormatException('Invalid claim response payload.');
        } else {
          throw Exception('Failed to submit claim');
        }
      } else {
        // No image, use regular JSON payload
        final payload = <String, dynamic>{
          'message': message,
          'contactName': contactName.trim(),
          'email': email.trim(),
          'phoneNumber': phoneNumber.trim(),
        };

        final response = await ApiClient.client.post(
          '/api/items/$id/claim',
          data: payload,
        );
        if (response.statusCode == 200) {
          final itemPayload = _extractItemPayload(response.data);
          if (itemPayload != null) {
            return Item.fromJson(itemPayload);
          }
          throw const FormatException('Invalid claim response payload.');
        } else {
          throw Exception('Failed to submit claim');
        }
      }
    } catch (e) {
      if (e is DioException) {
        print(
          'POST /api/items/$id/claim failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> postAiFeedback({
    required int itemId,
    required int matchedItemId,
    required String action, // positive | negative | dismissed
    String? source, // home | recommended | detail | matches
  }) async {
    try {
      await ApiClient.client.post(
        '/api/ai/feedback',
        data: {
          'itemId': itemId,
          'matchedItemId': matchedItemId,
          'action': action,
          if (source != null) 'source': source,
        },
      );
    } catch (e) {
      // Do not throw; feedback is best-effort
      if (e is DioException) {
        print(
          'POST /api/ai/feedback failed: status=${e.response?.statusCode} data=${e.response?.data}',
        );
      }
      print('AI feedback error: $e');
    }
  }

  Map<String, dynamic>? _extractItemPayload(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (raw['item'] is Map) {
        return Map<String, dynamic>.from(raw['item'] as Map);
      }
      if (raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      if (raw.containsKey('id')) {
        return raw;
      }
    } else if (raw is Map) {
      if (raw['item'] is Map) {
        return Map<String, dynamic>.from(raw['item'] as Map);
      }
      if (raw['data'] is Map) {
        return Map<String, dynamic>.from(raw['data'] as Map);
      }
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }
}
