import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart'
    show MatchScoreItem;
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
// import 'package:navistfind/features/lost_found/item/presentation/item_category_list.dart';
//import 'package:mobile_app/features/item/presentation/items_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
// import removed: ai_match_card (Matches tab removed)
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Department { treasury, state }

class LostAndFoundScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const LostAndFoundScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<LostAndFoundScreen> createState() => _LostAndFoundScreenState();
}

class _FoundTab extends ConsumerWidget {
  final String searchQuery;
  final ItemStatus? filterStatus;
  final AsyncValue<List<MatchScoreItem>> recommendedAsync;
  const _FoundTab({
    required this.searchQuery,
    required this.filterStatus,
    required this.recommendedAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsyncValue = ref.watch(itemsByTypeProvider(ItemType.found));
    return itemsAsyncValue.when(
      data: (items) {
        final filtered = items.where((item) {
          final q = searchQuery.toLowerCase();
          final matchesSearch =
              q.isEmpty ||
              item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.location.toLowerCase().contains(q);
          final matchesFilter =
              filterStatus == null || item.status == filterStatus;
          return matchesSearch && matchesFilter;
        }).toList();
        return _LostAndFoundScreenState()._buildNetflixList(
          filtered,
          recommendedAsync,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _LostAndFoundScreenState()._buildErrorState(e),
    );
  }
}

class _LostTab extends ConsumerWidget {
  final String searchQuery;
  final ItemStatus? filterStatus;
  final AsyncValue<List<MatchScoreItem>> recommendedAsync;
  const _LostTab({
    required this.searchQuery,
    required this.filterStatus,
    required this.recommendedAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsyncValue = ref.watch(itemsByTypeProvider(ItemType.lost));
    return itemsAsyncValue.when(
      data: (items) {
        final filtered = items.where((item) {
          final q = searchQuery.toLowerCase();
          final matchesSearch =
              q.isEmpty ||
              item.name.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.location.toLowerCase().contains(q);
          final matchesFilter =
              filterStatus == null || item.status == filterStatus;
          return matchesSearch && matchesFilter;
        }).toList();
        return _LostAndFoundScreenState()._buildNetflixList(
          filtered,
          recommendedAsync,
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _LostAndFoundScreenState()._buildErrorState(e),
    );
  }
}

// Matches tab removed

class _MyPostsTab extends ConsumerWidget {
  const _MyPostsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postedAsync = ref.watch(postedItemsProvider);
    return postedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Failed to load your posts')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.post_add, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                const Text('You have no posts'),
              ],
            ),
          );
        }
        final sorted = [...items]
          ..sort(
            (a, b) => DateTime.parse(
              b.createdAt,
            ).compareTo(DateTime.parse(a.createdAt)),
          );
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sorted.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final p = sorted[i];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.inventory_2),
                title: Text(p.name),
                subtitle: Text(
                  '${p.status.name} • ${_relativeTime(p.createdAt)}',
                ),
                onTap: () => showItemDetailsModal(context, p.id),
              ),
            );
          },
        );
      },
    );
  }
}

String _relativeTime(String iso) {
  try {
    final dt = DateTime.parse(iso);
    final now = DateTime.now();
    final d = now.difference(dt);
    if (d.isNegative) return 'Just now';
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24)
      return '${d.inHours} hr${d.inHours == 1 ? '' : 's'} ago';
    if (d.inDays == 1) return 'Yesterday';
    if (d.inDays <= 7) return '${d.inDays} days ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  } catch (_) {
    return 'Unknown date';
  }
}

// CTA removed (FAB already exists)

class _LostAndFoundScreenState extends ConsumerState<LostAndFoundScreen>
    with SingleTickerProviderStateMixin {
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
    final recommendedAsync = ref.watch(recommendedItemsProvider);
    final int tabLength = 3;
    final int safeInitialIndex = widget.initialTabIndex.clamp(0, tabLength - 1);
    return DefaultTabController(
      length: tabLength,
      initialIndex: safeInitialIndex,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAF9),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: SafeArea(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
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
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: Center(
                              key: const ValueKey('modernSearch'),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.06),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF1C2A40),
                                          Color(0xFF35465E),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(1.5),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.search,
                                            color: Color(0xFF1C2A40),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              autofocus: true,
                                              textInputAction:
                                                  TextInputAction.search,
                                              onSubmitted: (v) {
                                                setState(() {
                                                  _searchQuery = v
                                                      .trim()
                                                      .toLowerCase();
                                                });
                                              },
                                              onChanged: (v) {
                                                setState(() {
                                                  _searchQuery = v
                                                      .toLowerCase();
                                                });
                                              },
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Search items, locations, categories…',
                                                hintStyle: TextStyle(
                                                  color: Color(0xFF7A7A7A),
                                                  fontSize: 15,
                                                ),
                                                border: InputBorder.none,
                                                isCollapsed: true,
                                                contentPadding:
                                                    EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                              ),
                                              style: const TextStyle(
                                                color: Color(0xFF1A1A1A),
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          // Always show a close to exit search UX
                                          IconButton(
                                            icon: const Icon(
                                              Icons.close,
                                              color: Color(0xFF1C2A40),
                                              size: 20,
                                            ),
                                            splashRadius: 20,
                                            onPressed: () {
                                              setState(() {
                                                _searchQuery = '';
                                                _searchController.clear();
                                                _isSearching = false;
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    isScrollable: false,
                    labelColor: const Color(0xFF1C2A40),
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    indicatorColor: const Color(0xFF1C2A40),
                    tabs: [
                      const Tab(text: 'Found'),
                      const Tab(text: 'Lost'),
                      const Tab(text: 'My Posts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            _FoundTab(
              searchQuery: _searchQuery,
              filterStatus: _filterStatus,
              recommendedAsync: recommendedAsync,
            ),
            _LostTab(
              searchQuery: _searchQuery,
              filterStatus: _filterStatus,
              recommendedAsync: recommendedAsync,
            ),
            const _MyPostsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PostItemScreen())),
          backgroundColor: const Color(0xFF1C2A40),
          child: const Icon(Icons.add, color: Color(0xFFF4B431)),
        ),
      ),
    );
  }

  Widget _buildNetflixList(
    List<Item> items,
    AsyncValue<List<MatchScoreItem>> recommendedAsync,
  ) {
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
    List<Item> recommendedItems = [];
    recommendedAsync.whenData((data) {
      recommendedItems = data
          .map((m) => m.item)
          .whereType<Item>()
          .toList()
          .take(6)
          .toList();
    });

    final Map<String, List<Item>> categoryMap = {
      'Recommended for You': recommendedItems,
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
                  const SizedBox.shrink(),
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

  // _filterItemsInternal removed (unused)

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
