import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_helpers.dart';

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
          color: const Color(0xFF1C2A40),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
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
                        color: const Color(0xFF1C2A40),
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(
                        color: Color(0xFF1C2A40),
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: const TextStyle(
                          color: Color(0xFF1C2A40),
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
                            color: Color(0xFF1C2A40),
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
              final createdAt = DateTime.tryParse(item.created_at);
              return createdAt != null && now.difference(createdAt).inDays <= 5;
            }).toList();
          }

          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where(
                  (item) => item.name.toLowerCase().contains(
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
    return GestureDetector(
      onTap: () => showItemDetailsModal(context, item.id),
      child: Container(
        width: 150,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF1C2A40).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2A40),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  getCategoryIcon(item.category),
                  size: 48,
                  color: const Color(0xFFF4B431), // Accent yellow
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildTypeChip(item.type),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.place,
                        size: 14,
                        color: Color(0xFF1C2A40),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF1C2A40),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(item.created_at),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(ItemType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: type == ItemType.lost ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        type == ItemType.lost ? 'Lost' : 'Found',
        style: TextStyle(
          color: type == ItemType.lost ? Colors.red : Colors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) return 'Just now';

      if (difference.inDays > 7) {
        return '${date.month}/${date.day}/${date.year}';
      } else if (difference.inDays >= 2) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} min ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
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
