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

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        print('Posted items: $data');
        return data.map((item) => PostedItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load posted items');
      }
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
