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
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> deleteItem(int id) async {
    try {
      await _service.deleteItem(id);
      state = AsyncData((state.value ?? []).where((item) => item.id != id).toList());
      return null;
    } catch (e) {
      return 'Failed to delete item';
    }
  }
}
