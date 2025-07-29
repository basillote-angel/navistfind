import 'dart:io';

import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:dio/dio.dart';

class PostItemService {
  Future<String?> postItem({
    required String itemName,
    required String category,    
    required String description,
    required String location,
    required DateTime date,
    required ItemType type,
  }) async{
    try {
      final formData = FormData.fromMap({
        'name': itemName,
        'category': category,
        'description': description,
        'location': location,
        'lost_found_date': date.toIso8601String(),
        'type': type.name,
      });

      final response = await ApiClient.client.post('/api/items', data: formData);

      if (response.statusCode != 201) {
        return response.data['message'] ?? 'Failed to post item';
      }

      return null;

    } catch(e) {
      print('Error: => $e');
      return 'Error: $e';
    }
  }
Future<String?> updateItem({
  required int itemId,
  required String itemName,
  required String category,
  required String description,
  required String location,
  required DateTime date,
  required ItemType type,
}) async {
  try {
    // JSON is fine here – no need for multipart
    final body = {
      'name'           : itemName,
      'category'       : category,
      'description'    : description,
      'location'       : location,
      'lost_found_date': date.toIso8601String(),
      'type': 'lost',
     // <‑‑ enum → 'lost' / 'found'
    };

    final response = await ApiClient.client.put('/api/items/$itemId', data: body);

    if (response.statusCode != 200) {
      return response.data['message'] ?? 'Failed to update item';
    }
    return null;
  } catch (e) {
    print('Update Error: $e');
    return 'Error: $e';
  }
}


}