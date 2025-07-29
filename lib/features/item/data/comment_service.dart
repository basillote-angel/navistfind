import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/item/domain/models/comment.dart';

class CommentService {
  Future<void> postComment({
    required String itemId,
    required String comment,
  }) async {
    try {
      // For the payload, user id and created should be handled by the backend
      final response = await ApiClient.client.post(
        '/api/comments',
        data: {
          'item_id': itemId,
          'comment': comment,
        },
      );

      if (response.statusCode != 201) {
        throw Exception(response.data['message'] ?? 'Failed to post comment');
      }
    } catch (e) {
      print('Error posting comment: $e');
      rethrow;
    }
  }

  Future<List<Comment>> fetchComments(String itemId) async {
    try {
      final response = await ApiClient.client.get(
        '/api/comments?item_id=$itemId',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((comment) => Comment.fromJson(comment)).toList();
      } else {
        throw Exception('Failed to load comments: ${response.statusCode}');
      }
    } catch (e) {
      print('Fetch Error: $e');
      rethrow;
    }
  }
}
