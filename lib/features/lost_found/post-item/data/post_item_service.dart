import 'package:navistfind/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/category_id_mapping.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

import 'package:navistfind/core/utils/date_formatter.dart';

class PostItemService {
  Future<String?> postItem({
    required String title,
    required ItemCategory category,
    required String description,
    required String location,
    required DateTime date,
    required ItemType type,
  }) async {
    try {
      final catId = await categoryIdFromEnumAsync(category);
      if (catId == null) {
        return 'Unknown category mapping';
      }

      final body = {
        'title': title,
        'category_id': catId,
        'description': description,
        'location': location,
        'date': DateFormatter.formatDateForApi(date),
        'type': type.name,
      };

      final response = await ApiClient.client.post('/api/items', data: body);
      if (response.statusCode != 201) {
        try {
          final data = response.data;
          if (data is Map && data['message'] is String) {
            return data['message'] as String;
          }
        } catch (_) {}
        return 'Failed to post item (status: ${response.statusCode})';
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        print('POST /api/items failed: status=$status data=$data');
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
        if (status == 403) return 'Forbidden: only staff can post found items';
        if (status == 422) {
          return 'Validation failed: please select a valid category and date';
        }
        return 'Server error (status: $status)';
      }
      print('Error: => $e');
      return 'Unknown error: $e';
    }
  }

  Future<String?> updateItem({
    required int itemId,
    required String title,
    required ItemCategory category,
    required String description,
    required String location,
    required DateTime date,
    required ItemType type,
  }) async {
    try {
      final catId = await categoryIdFromEnumAsync(category);
      if (catId == null) {
        return 'Unknown category mapping';
      }

      final body = {
        'title': title,
        'category_id': catId,
        'description': description,
        'location': location,
        'date': DateFormatter.formatDateForApi(date),
        'type': type.name,
      };

      final response = await ApiClient.client.put(
        '/api/items/$itemId',
        data: body,
      );
      if (response.statusCode != 200) {
        try {
          final data = response.data;
          if (data is Map && data['message'] is String) {
            return data['message'] as String;
          }
        } catch (_) {}
        return 'Failed to update item (status: ${response.statusCode})';
      }
      return null;
    } catch (e) {
      if (e is DioException) {
        final status = e.response?.statusCode;
        final data = e.response?.data;
        print('PUT /api/items/$itemId failed: status=$status data=$data');
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
        if (status == 422) return 'Validation failed: please check fields';
        return 'Server error (status: $status)';
      }
      print('Update Error: $e');
      return 'Unknown error: $e';
    }
  }
}
