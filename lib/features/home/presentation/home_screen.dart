import 'package:navistfind/features/item/application/item_provider.dart';
import 'package:navistfind/features/item/domain/models/item.dart';
import 'package:navistfind/features/item/domain/enums/item_status.dart';
import 'package:navistfind/features/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/item/presentation/item_category_list.dart';
//import 'package:mobile_app/features/item/presentation/items_screen.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/post-item/domain/enums/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Department { treasury, state }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';
  ItemStatus? _filterStatus;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsyncValue = ref.watch(itemListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF9),
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              color: const Color(0xFFFAFAF9),
              child: Row(
                children: [
                  if (!_isSearching)
                    Expanded(
                      child: Text(
                        'Lost & Found',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1C2A40),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  if (_isSearching)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAF9),
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
                            color: Color(0xFF1A1A1A),
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search',
                            hintStyle: const TextStyle(
                              color: Color(0xFF1A1A1A),
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
                      icon: const Icon(
                        Icons.search,
                        color: Color(0xFF1C2A40),
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                ],
              ),
            ),
            // Main Content (Scrollable)
            Expanded(
              child: itemsAsyncValue.when(
                data: (items) {
                  final filteredItems = items.where((item) {
                    final matchesSearch =
                        _searchQuery.isEmpty ||
                        item.name.toLowerCase().contains(_searchQuery) ||
                        item.description.toLowerCase().contains(_searchQuery) ||
                        item.location.toLowerCase().contains(_searchQuery);
                    final matchesFilter =
                        _filterStatus == null || item.status == _filterStatus;
                    return matchesSearch && matchesFilter;
                  }).toList();
                  return _buildNetflixList(filteredItems);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetflixList(List<Item> items) {
    if (items.isEmpty) return _buildEmptyState();
    final now = DateTime.now();
    final recentItems =
        items.where((item) {
          final createdAt = DateTime.tryParse(item.created_at);
          return createdAt != null && now.difference(createdAt).inDays <= 5;
        }).toList()..sort(
          (a, b) => DateTime.parse(
            b.created_at,
          ).compareTo(DateTime.parse(a.created_at)),
        );
    final Map<String, List<Item>> categoryMap = {
      'Recommended for You': items.take(6).toList(),
      'Recently Posted Items': recentItems,
      'Electronic': items
          .where((i) => i.category == ItemCategory.electronics)
          .toList(),
      'Document': items
          .where((i) => i.category == ItemCategory.documents)
          .toList(),
      'Accessories': items
          .where((i) => i.category == ItemCategory.accessories)
          .toList(),
      'ID and Cards': items
          .where((i) => i.category == ItemCategory.idOrCards)
          .toList(),
      'Clothing': items
          .where((i) => i.category == ItemCategory.clothing)
          .toList(),
      'Bag and Pouches': items
          .where((i) => i.category == ItemCategory.bagOrPouches)
          .toList(),
      'Personal Item': items
          .where((i) => i.category == ItemCategory.personalItems)
          .toList(),
      'School Supplies': items
          .where((i) => i.category == ItemCategory.schoolSupplies)
          .toList(),
      'Others Types': items
          .where((i) => i.category == ItemCategory.others)
          .toList(),
    };
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: categoryMap.length,
      itemBuilder: (context, index) {
        final title = categoryMap.keys.elementAt(index);
        final items = categoryMap[title]!;
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      if (title == 'Recommended for You') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemsScreen(
                              title: 'Recommended for You',
                              recommendedOnly: true,
                            ),
                          ),
                        );
                      } else if (title == 'Recently Posted Items') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemsScreen(
                              title: 'Recently Posted Items',
                              showRecentOnly: true,
                            ),
                          ),
                        );
                      } else {
                        final categoryMap = {
                          'Electronic': ItemCategory.electronics,
                          'Document': ItemCategory.documents,
                          'Accessories': ItemCategory.accessories,
                          'ID and Cards': ItemCategory.idOrCards,
                          'Clothing': ItemCategory.clothing,
                          'Bag and Pouches': ItemCategory.bagOrPouches,
                          'Personal Item': ItemCategory.personalItems,
                          'School Supplies': ItemCategory.schoolSupplies,
                          'Others Types': ItemCategory.others,
                        };
                        final selectedCategory = categoryMap[title];
                        if (selectedCategory != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemsScreen(
                                title: title,
                                filterCategory: selectedCategory,
                              ),
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1C2A40),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, idx) =>
                    _buildNetflixItemCard(context, items[idx]),
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.isNegative) return 'Just now'; // Future date

      if (difference.inDays > 7) {
        return '${date.month}/${date.day}/${date.year}';
      } else if (difference.inDays >= 2) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inHours >= 1) {
        return '${difference.inHours} hr${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes >= 1) {
        return '${difference.inMinutes} min ago'; // <== changed here
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  Widget _buildNetflixItemCard(BuildContext context, Item item) {
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

  IconData getCategoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics:
        return Icons.devices_other;
      case ItemCategory.documents:
        return Icons.description;
      case ItemCategory.accessories:
        return Icons.watch;
      case ItemCategory.idOrCards:
        return Icons.badge;
      case ItemCategory.clothing:
        return Icons.checkroom;
      case ItemCategory.bagOrPouches:
        return Icons.backpack;
      case ItemCategory.personalItems:
        return Icons.assignment_ind;
      case ItemCategory.schoolSupplies:
        return Icons.library_books;
      case ItemCategory.others:
        return Icons.category;
    }
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _filterStatus != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No items match your search',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _filterStatus = null;
                });
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No items available',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Items that are lost or found will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load items',
            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final _ = ref.refresh(itemListProvider);
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
