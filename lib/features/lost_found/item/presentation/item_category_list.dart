import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/widgets/item_card.dart';

class CategoryItemsView extends ConsumerStatefulWidget {
  final String title;
  final ItemCategory? filterCategory;
  final bool showRecentOnly;
  final bool recommendedOnly;

  const CategoryItemsView({
    super.key,
    required this.title,
    this.filterCategory,
    this.showRecentOnly = false,
    this.recommendedOnly = false,
  });

  @override
  ConsumerState<CategoryItemsView> createState() => _CategoryItemsViewState();
}

class _CategoryItemsViewState extends ConsumerState<CategoryItemsView> {
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: const Color(0xFF123A7D),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              if (!_isSearching)
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              if (_isSearching)
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF123A7D),
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        color: Color(0xFF123A7D),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                          color: Color(0xFF123A7D),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 0,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF123A7D),
                          ),
                          onPressed: () {
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                    ),
                  ),
                ),
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white, size: 28),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          final now = DateTime.now();
          List<Item> filtered = items;

          if (widget.filterCategory != null) {
            filtered = filtered
                .where((i) => i.category == widget.filterCategory)
                .toList();
          }

          if (widget.showRecentOnly) {
            filtered = filtered.where((item) {
              final createdAt = DateTime.tryParse(item.createdAt);
              return createdAt != null && now.difference(createdAt).inDays <= 5;
            }).toList();
          }

          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where(
                  (item) => item.title.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();
          }

          if (widget.recommendedOnly) {
            filtered = filtered.take(10).toList();
          }

          if (filtered.isEmpty) {
            return const Center(
              child: Text(
                "No items found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.65,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _buildItemCard(context, filtered[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => const Center(
          child: Text(
            'Error loading items',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return ItemCard(
      item: item,
      cardWidth: 150,
      headerHeight: 110,
      radius: 16,
      borderOpacity: 0.2,
      borderWidth: 1,
      iconSize: 48,
      titleFontSize: 15,
      chipFontSize: 11,
      onTap: () => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ItemDetailsModal(itemId: item.id, type: item.type),
      ),
    );
  }
}

class ItemSearchDelegate extends SearchDelegate<String> {
  @override
  String? get searchFieldLabel => 'Search items...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
