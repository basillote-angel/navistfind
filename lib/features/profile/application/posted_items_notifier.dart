import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/profile/data/profile_service.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';

class PostedItemsNotifier extends StateNotifier<AsyncValue<List<PostedItem>>> {
  final ProfileService _service;

  PostedItemsNotifier(this._service) : super(const AsyncLoading()) {
    loadItems();
  }

  Future<void> loadItems() async {
    try {
      final items = await _service.fetchPostedItems();
      state = AsyncData(items);
    } catch (e) {
      // Fail-soft: on server errors, show empty list instead of crashing the tab
      // Still log the error for debugging
      // ignore: avoid_print
      print('postedItems load error: $e');
      state = const AsyncData(<PostedItem>[]);
    }
  }

  Future<String?> deleteItem(int id) async {
    final previousItems = state.value ?? <PostedItem>[];
    PostedItem? itemToDelete;
    for (final candidate in previousItems) {
      if (candidate.id == id) {
        itemToDelete = candidate;
        break;
      }
    }

    // Optimistic update: remove locally before calling API
    final optimisticallyUpdated = previousItems
        .where((it) => it.id != id)
        .toList();
    state = AsyncData(optimisticallyUpdated);

    try {
      await _service.deleteItem(id, type: itemToDelete?.type);
      // Refresh from server to ensure consistency
      final refreshed = await _service.fetchPostedItems();
      state = AsyncData(refreshed);
      return null;
    } catch (e) {
      // Rollback on failure
      state = AsyncData(previousItems);
      return 'Failed to delete item';
    }
  }
}
