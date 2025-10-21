import 'package:navistfind/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

class ItemService {
  Future<List<Item>> fetchItems() async {
    try {
      final response = await ApiClient.client.get('/api/items');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((item) => Item.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load items');
      }
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

  Future<Item> fetchItemDetails(int id) async {
    try {
      final response = await ApiClient.client.get('/api/items/$id');

      if (response.statusCode == 200) {
        final data = response.data;
        return Item.fromJson(data);
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
        if (body is List) {
          return body.map((item) => MatchScoreItem.fromJson(item)).toList();
        }
        if (body is Map && body['data'] is List) {
          final list = body['data'] as List;
          return list.map((item) => MatchScoreItem.fromJson(item)).toList();
        }
        return <MatchScoreItem>[];
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
      if (category != null) params['category'] = category.name;
      if (dateFrom != null) params['dateFrom'] = _fmtDate(dateFrom);
      if (dateTo != null) params['dateTo'] = _fmtDate(dateTo);
      params['sort'] = sort;

      final response = await ApiClient.client.get(
        '/api/items',
        queryParameters: params,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((j) => Item.fromJson(j)).toList();
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

  String _fmtDate(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<Item> claimFoundItem({
    required int id,
    required String message,
    String? contactName,
    String? contactInfo,
  }) async {
    try {
      final payload = <String, dynamic>{'message': message};
      if (contactName != null && contactName.trim().isNotEmpty) {
        payload['contactName'] = contactName.trim();
      }
      if (contactInfo != null && contactInfo.trim().isNotEmpty) {
        payload['contactInfo'] = contactInfo.trim();
      }

      final response = await ApiClient.client.post(
        '/api/items/$id/claim',
        data: payload,
      );
      if (response.statusCode == 200) {
        return Item.fromJson(response.data);
      } else {
        throw Exception('Failed to submit claim');
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
}
