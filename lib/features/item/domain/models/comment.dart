import 'package:navistfind/features/profile/domain/models/user.dart';

class Comment {
  final int id;
  final int itemId;
  final int userId;
  final String comment;
  final String createdAt;
  final User user;

  Comment({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.comment,
    required this.createdAt,
    required this.user,
  });

  // Avoid using fallback values
  // We must be consistent with the API response on json parsing
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      itemId: json['item_id'],
      userId: json['user_id'],
      comment: json['comment'],
      createdAt: json['created_at'],
      user: User.fromJson(json['user']),
    );
  }
}
