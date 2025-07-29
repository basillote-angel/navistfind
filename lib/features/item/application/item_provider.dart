import 'package:navistfind/features/item/data/item_service.dart';
import 'package:navistfind/features/item/domain/models/item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final itemServiceProvider = Provider((ref) => ItemService());

final itemListProvider = FutureProvider<List<Item>>((ref) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchItems();
});

final itemDetailsProvider = FutureProvider.family<Item, int>((ref, itemId) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchItemDetails(itemId);
});

final matchesItemsProvider = FutureProvider.family<List<MatchScoreItem>, int>((ref, itemId) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchMatchesItems(itemId);
});