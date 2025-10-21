import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';

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

  Future<void> deleteItem(int id) async {
    final response = await ApiClient.client.delete('/api/items/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete item');
    }
  }
}
