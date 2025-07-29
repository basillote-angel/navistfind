import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/item/domain/models/item.dart';

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
      print('Error: $e');
      rethrow;
    }
  }
}
