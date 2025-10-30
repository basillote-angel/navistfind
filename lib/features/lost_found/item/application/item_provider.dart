import 'package:navistfind/features/lost_found/item/data/item_service.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';

final itemServiceProvider = Provider((ref) => ItemService());

final itemListProvider = FutureProvider<List<Item>>((ref) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchItems();
});

final itemDetailsProvider = FutureProvider.family<Item, int>((
  ref,
  itemId,
) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchItemDetails(itemId);
});

final itemDetailsWithTypeProvider =
    FutureProvider.family<Item, ({int id, ItemType type})>((ref, args) async {
      final itemService = ref.read(itemServiceProvider);
      return await itemService.fetchItemDetails(args.id, type: args.type);
    });

final matchesItemsProvider = FutureProvider.family<List<MatchScoreItem>, int>((
  ref,
  itemId,
) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchMatchesItems(itemId);
});

final recommendedItemsProvider = FutureProvider<List<MatchScoreItem>>((
  ref,
) async {
  final itemService = ref.read(itemServiceProvider);
  return await itemService.fetchRecommendedItems();
});

// Search/Filter state
final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedTypeProvider = StateProvider<ItemType?>((ref) => null);
final selectedCategoryProvider = StateProvider<ItemCategory?>((ref) => null);
final dateFromProvider = StateProvider<DateTime?>((ref) => null);
final dateToProvider = StateProvider<DateTime?>((ref) => null);
final sortOptionProvider = StateProvider<String>(
  (ref) => 'newest',
); // newest | relevance

// Filtered list provider
final filteredItemListProvider = FutureProvider<List<Item>>((ref) async {
  final service = ref.read(itemServiceProvider);

  final query = ref.watch(searchQueryProvider);
  final type = ref.watch(selectedTypeProvider);
  final category = ref.watch(selectedCategoryProvider);
  final dateFrom = ref.watch(dateFromProvider);
  final dateTo = ref.watch(dateToProvider);
  final sort = ref.watch(sortOptionProvider);

  return service.fetchItemsFiltered(
    query: query.isEmpty ? null : query,
    type: type,
    category: category,
    dateFrom: dateFrom,
    dateTo: dateTo,
    sort: sort,
  );
});

final itemsByTypeProvider = FutureProvider.family<List<Item>, ItemType>((
  ref,
  type,
) async {
  final service = ref.read(itemServiceProvider);

  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final dateFrom = ref.watch(dateFromProvider);
  final dateTo = ref.watch(dateToProvider);
  final sort = ref.watch(sortOptionProvider);

  return service.fetchItemsFiltered(
    query: query.isEmpty ? null : query,
    type: type,
    category: category,
    dateFrom: dateFrom,
    dateTo: dateTo,
    sort: sort,
  );
});
