import 'package:navistfind/core/constants.dart';
import 'package:navistfind/features/item/application/item_provider.dart';
import 'package:navistfind/features/item/domain/models/item.dart';
import 'package:navistfind/features/item/domain/enums/item_status.dart';
import 'package:navistfind/features/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/post-item/domain/enums/category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Department { treasury, state }

class ItemsScreen extends ConsumerStatefulWidget {
  const ItemsScreen({super.key});

  @override
  ConsumerState<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends ConsumerState<ItemsScreen> {
  String _searchQuery = '';
  ItemStatus? _filterStatus;
  ItemCategory? _selectedCategory; 

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemsAsyncValue = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "Lost & Found Items",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 32, color: Colors.black45),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar and Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search items...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ItemCategory?>(
                      value: _selectedCategory,
                      icon: const Icon(Icons.arrow_drop_down),
                      hint: const Text("Category"),
                      items: [
                        const DropdownMenuItem<ItemCategory?>(
                          value: null,
                          child: Text("All"),
                        ),
                        ...ItemCategory.values.map((category) {
                          return DropdownMenuItem<ItemCategory>(
                            value: category,
                            child: Text(category.label),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    ),
                  ),
                ),

              ],
            ),
          ),

          // Main Content (Scrollable)
          Expanded(
            child: itemsAsyncValue.when(
              data: (items) {
                final filteredItems =
                    items.where((item) {
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          item.name.toLowerCase().contains(_searchQuery) ||
                          item.description.toLowerCase().contains(
                            _searchQuery,
                          ) ||
                          item.location.toLowerCase().contains(_searchQuery);

                      final matchesFilter = 
                          _filterStatus == null || item.status == _filterStatus;
                      final matchesCategory = 
                          _selectedCategory == null || item.category == _selectedCategory;


                      return matchesSearch && matchesFilter && matchesCategory;

                    }).toList();

                return _buildList(filteredItems);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),
        ],
      ),
    );
  }

  // void _showFilterOptions() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) {
  //       return StatefulBuilder(
  //         builder: (context, setModalState) {
  //           return Padding(
  //             padding: const EdgeInsets.all(16.0),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               crossAxisAlignment: CrossAxisAlignment.stretch,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40,
  //                     height: 4,
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[300],
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'Filter Items',
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 16),
  //                 const Text(
  //                   'Status',
  //                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 Wrap(
  //                   spacing: 8,
  //                   children:
  //                       ItemStatus.values.map((status) {
  //                         final isSelected = _filterStatus == status;
  //                         return FilterChip(
  //                           label: Text(_getStatusText(status)),
  //                           selected: isSelected,
  //                           onSelected: (selected) {
  //                             setModalState(() {
  //                               setState(() {
  //                                 _filterStatus = selected ? status : null;
  //                               });
  //                             });
  //                           },
  //                           backgroundColor: Colors.grey[100],
  //                           selectedColor: Colors.green[100],
  //                           checkmarkColor: Colors.green,
  //                         );
  //                       }).toList(),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                   children: [
  //                     TextButton(
  //                       onPressed: () {
  //                         setState(() {
  //                           _filterStatus = null;
  //                         });
  //                         Navigator.pop(context);
  //                       },
  //                       child: const Text('Clear All'),
  //                     ),
  //                     ElevatedButton(
  //                       onPressed: () {
  //                         Navigator.pop(context);
  //                       },
  //                       style: ElevatedButton.styleFrom(
  //                         backgroundColor: Colors.green,
  //                         foregroundColor: Colors.white,
  //                       ),
  //                       child: const Text('Apply'),
  //                     ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // String _getStatusText(ItemStatus status) {
  //   switch (status) {
  //     case ItemStatus.claimed:
  //       return 'Claimed';
  //     case ItemStatus.unclaimed:
  //       return 'Unclaimed';
  //   }
  // }
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
        return '${difference.inMinutes} min ago';  // <== changed here
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

Widget _buildList(List<Item> items) {
  if (items.isEmpty) {
    return _buildEmptyState();
  }

  // Sort items by createdAt descending (newest first)
  items.sort((a, b) => DateTime.parse(b.created_at).compareTo(DateTime.parse(a.created_at)));

  return RefreshIndicator(
    onRefresh: () async {
       ref.refresh(itemListProvider);
    },
    child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Container(
                height: 40,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recently Posted Items',
                      style: const TextStyle(fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ItemsScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: Colors.black54,
                        textStyle: const TextStyle(fontSize: 14),
                        minimumSize: Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 12.0, 18.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1, // Fixed number of columns
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 4.5, // Fixed aspect ratio to control height
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return _buildItemCard(item);
              }, childCount: items.length),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildItemCard(Item item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      color: Colors.grey[50],
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFDDDDDD)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showItemDetailsModal(context, item.id),
        child: Padding(
          padding: const EdgeInsets.all(8),
           child: Row(
          children: [
            // Category icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getCategoryIcon(item.category),  
                size: 32,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(width: 12),
       
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(item.created_at),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  _buildTypeChip(item.type),   
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(ItemType type) {
    Color indicatorColor;
    String label;
    switch (type) {
      case ItemType.lost:
        indicatorColor = Colors.red;
        label = 'Lost Item';
        break;
      case ItemType.found:
        indicatorColor = Colors.green;
        label = 'Found Item';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 14,
            height: 14,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: indicatorColor,
              shape: BoxShape.circle,
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
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
                  _searchController.clear();
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
