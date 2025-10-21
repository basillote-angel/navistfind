import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/item/data/comment_service.dart';
import 'package:navistfind/features/lost_found/item/domain/models/comment.dart';

class CommentNotifier extends StateNotifier<AsyncValue<void>> {
  final CommentService _service;

  CommentNotifier(this._service) : super(const AsyncValue.data(null));

  Future<void> postComment({
    required String itemId,
    required String comment,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.postComment(
        itemId: itemId,
        comment: comment,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final commentsProvider = Provider<CommentService>((ref) => CommentService());

final commentStateProvider =
    StateNotifierProvider<CommentNotifier, AsyncValue<void>>((ref) {
      final service = ref.read(commentsProvider);
      return CommentNotifier(service);
    });

final commentListProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  itemId,
) {
  final service = ref.read(commentsProvider);
  return service.fetchComments(itemId);
});
// Service provider
final commentServiceProvider = Provider<CommentService>(
  (ref) => CommentService(),
);

// Family provider for comments
final itemCommentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  itemId,
) {
  final service = ref.read(commentServiceProvider);
  return service.fetchComments(itemId);
});
