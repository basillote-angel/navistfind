import 'package:navistfind/core/network/api_client.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';

class ProfileService {
  Future<User> fetchInfo() async {
    try {
      final response = await ApiClient.client.get('/api/user');

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        return User.fromJson(data);
      } else {
        throw Exception('Failed to load items');
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<List<PostedItem>> fetchPostedItems() async {
    try {
      final response = await ApiClient.client.get('/api/me/items');
      final status = response.statusCode ?? 500;

      if (status == 200) {
        final body = response.data;
        if (body is List) {
          final List<PostedItem> parsed = [];
          for (final e in body) {
            if (e is Map) {
              try {
                parsed.add(PostedItem.fromJson(Map<String, dynamic>.from(e)));
              } catch (_) {
                // skip bad rows
              }
            }
          }
          return parsed;
        }
        if (body is Map && body['data'] is List) {
          final list = body['data'] as List;
          final List<PostedItem> parsed = [];
          for (final e in list) {
            if (e is Map) {
              try {
                parsed.add(PostedItem.fromJson(Map<String, dynamic>.from(e)));
              } catch (_) {
                // skip bad rows
              }
            }
          }
          return parsed;
        }
        return <PostedItem>[];
      }

      if (status == 204 || status == 404) {
        return <PostedItem>[];
      }

      throw Exception('Failed to load posted items (status: $status)');
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(int id, {ItemType? type}) async {
    // Debug logging
    // Prefer query param for DELETE to ensure Laravel receives type
    final query = type != null ? '?type=${type.name}' : '';
    // ignore: avoid_print
    print('DELETE /api/items/$id$query');
    final response = await ApiClient.client.delete(
      '/api/items/$id$query',
      options: Options(
        // Always return Response so we can log status/body even on errors
        validateStatus: (status) => true,
        contentType: Headers.jsonContentType,
      ),
    );
    // ignore: avoid_print
    print('DELETE status=${response.statusCode} data=${response.data}');
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return;
    }

    // Fallback: if not found and we sent a type, try the opposite type once
    if (status == 404 && type != null) {
      final altType = type == ItemType.lost ? ItemType.found : ItemType.lost;
      final altQuery = '?type=${altType.name}';
      // ignore: avoid_print
      print('DELETE retry with alt type: /api/items/$id$altQuery');
      final retry = await ApiClient.client.delete(
        '/api/items/$id$altQuery',
        options: Options(
          validateStatus: (s) => true,
          contentType: Headers.jsonContentType,
        ),
      );
      // ignore: avoid_print
      print('DELETE retry status=${retry.statusCode} data=${retry.data}');
      final retryStatus = retry.statusCode ?? 0;
      if (retryStatus >= 200 && retryStatus < 300) {
        return;
      }
      if (retryStatus == 404) {
        // Treat 404 as idempotent success after trying both types
        return;
      }
      throw Exception('Failed to delete item (status: $retryStatus)');
    }

    // If no type was provided and server says 404, treat as idempotent success
    if (status == 404) {
      return;
    }

    throw Exception('Failed to delete item (status: $status)');
  }
}
