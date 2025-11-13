import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/edit_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/widgets/item_card.dart';
import 'package:navistfind/widgets/posted_item_card.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/core/utils/status_utils.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_dialogs.dart';
import 'package:navistfind/widgets/action_sheet_button.dart';
import 'package:navistfind/widgets/status_header.dart';
import 'package:navistfind/widgets/section_header.dart';
import 'package:navistfind/widgets/empty_state.dart';
import 'package:navistfind/widgets/loading_placeholders.dart';

// Lost & Found screen

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
  final Set<String> expandedCategories;
  final Function(String) onToggleCategory;
  const _FoundTab({
    required this.searchQuery,
    required this.filterStatus,
    required this.recommendedAsync,
    required this.expandedCategories,
    required this.onToggleCategory,
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
              item.title.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.location.toLowerCase().contains(q);
          final matchesFilter =
              filterStatus == null || item.status == filterStatus;
          return matchesSearch && matchesFilter;
        }).toList();
        return _LostAndFoundScreenState()._buildNetflixList(
          filtered,
          recommendedAsync,
          expandedCategories,
          onToggleCategory,
        );
      },
      loading: () => _ShimmerLoadingPlaceholder(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load items',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final _ = ref.refresh(itemsByTypeProvider(ItemType.found));
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LostTab extends ConsumerWidget {
  final String searchQuery;
  final ItemStatus? filterStatus;
  final AsyncValue<List<MatchScoreItem>> recommendedAsync;
  final Set<String> expandedCategories;
  final Function(String) onToggleCategory;
  const _LostTab({
    required this.searchQuery,
    required this.filterStatus,
    required this.recommendedAsync,
    required this.expandedCategories,
    required this.onToggleCategory,
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
              item.title.toLowerCase().contains(q) ||
              item.description.toLowerCase().contains(q) ||
              item.location.toLowerCase().contains(q);
          final matchesFilter =
              filterStatus == null || item.status == filterStatus;
          return matchesSearch && matchesFilter;
        }).toList();
        return _LostAndFoundScreenState()._buildNetflixList(
          filtered,
          recommendedAsync,
          expandedCategories,
          onToggleCategory,
        );
      },
      loading: () => _ShimmerLoadingPlaceholder(),
      error: (e, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Failed to load items',
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final _ = ref.refresh(itemsByTypeProvider(ItemType.lost));
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
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
      loading: () => _ShimmerLoadingPlaceholder(),
      error: (e, _) => _buildErrorState(ref),
      data: (items) {
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group items by status
        final groupedItems = _groupItemsByStatus(items);

        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 120, // Extra space for FAB
            top: AppTheme.spacingL,
            left: 20,
            right: 20,
          ),
          itemCount: groupedItems.length,
          itemBuilder: (context, index) {
            final entry = groupedItems.entries.elementAt(index);
            final status = entry.key;
            final statusItems = entry.value;

            return Padding(
              padding: EdgeInsets.only(
                bottom: index == groupedItems.length - 1
                    ? 0
                    : AppTheme.spacingXXL,
              ),
              child: _buildStatusSection(context, status, statusItems),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 64,
                color: AppTheme.errorRed,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text('Failed to load your posts', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Please check your connection and try again',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(postedItemsProvider.notifier).loadItems();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: AppTheme.getPrimaryButtonStyle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              child: const Icon(
                Icons.post_add,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text('No Posts Yet', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Start by posting your first lost or found item',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    String status,
    List<PostedItem> items,
  ) {
    final statusIcon = getStatusIconFromString(status);
    final statusColor = getStatusColorFromString(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status Header with Divider (reusable)
        StatusHeader(
          icon: statusIcon,
          label: getUserFriendlyStatusLabelFromString(status),
          count: items.length,
          color: statusColor,
        ),
        // Horizontal Scrollable Cards
        SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemExtent: 190 + 12, // itemCardWidth + itemHorizontalGap
            itemCount: items.length,
            itemBuilder: (context, index) {
              final rightPad = (index == items.length - 1) ? 0.0 : 12.0;
              return Padding(
                padding: EdgeInsets.only(right: rightPad),
                child: _buildMyPostCard(context, items[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyPostCard(BuildContext context, PostedItem item) {
    return PostedItemCard(
      postedItem: item,
      cardWidth: 190,
      radius: AppTheme.radiusLarge,
      onTap: () => showItemDetailsModal(context, item.id),
      onLongPress: () => _showItemActionSheet(context, item),
    );
  }

  void _showItemActionSheet(BuildContext outerContext, PostedItem item) {
    final canEditDelete = item.status == ItemStatus.open;

    showModalBottomSheet(
      context: outerContext,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Item info header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Icon(
                            CategoryUtils.getIcon(item.category),
                            color: AppTheme.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTheme.heading4,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.location,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textGray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Action buttons
              ActionSheetButton(
                icon: Icons.edit_outlined,
                label: 'Edit',
                enabled: canEditDelete,
                disabledReason: canEditDelete
                    ? null
                    : _getEditDisabledReason(item.status),
                color: AppTheme.primaryBlue,
                onTap: canEditDelete
                    ? () {
                        Navigator.pop(context);
                        Navigator.push(
                          outerContext,
                          MaterialPageRoute(
                            builder: (_) => EditItemScreen(item: item),
                          ),
                        );
                      }
                    : () {
                        Navigator.pop(context);
                        ItemDialogs.showCannotEditDialog(
                          outerContext,
                          item.status,
                        );
                      },
              ),
              ActionSheetButton(
                icon: Icons.delete_outline,
                label: 'Delete',
                enabled: canEditDelete,
                disabledReason: canEditDelete
                    ? null
                    : _getDeleteDisabledReason(item.status),
                color: AppTheme.errorRed,
                onTap: canEditDelete
                    ? () {
                        Navigator.pop(context);
                        _showDeleteConfirmation(outerContext, item);
                      }
                    : () {
                        Navigator.pop(context);
                        ItemDialogs.showCannotDeleteDialog(
                          outerContext,
                          item.status,
                        );
                      },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  String _getEditDisabledReason(ItemStatus status) {
    switch (status) {
      case ItemStatus.matched:
        return 'Item is matched';
      case ItemStatus.returned:
        return 'Item already returned';
      case ItemStatus.closed:
        return 'Item is closed';
      case ItemStatus.unclaimed:
        return 'Item is unclaimed';
      case ItemStatus.open:
        return '';
    }
  }

  String _getDeleteDisabledReason(ItemStatus status) {
    switch (status) {
      case ItemStatus.matched:
        return 'Cannot delete matched item';
      case ItemStatus.returned:
        return 'Cannot delete returned item';
      case ItemStatus.closed:
        return 'Cannot delete closed item';
      case ItemStatus.unclaimed:
        return 'Cannot delete unclaimed item';
      case ItemStatus.open:
        return '';
    }
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    PostedItem item,
  ) async {
    final confirmed = await ItemDialogs.showDeleteConfirmationDialog(
      context,
      title: item.name,
    );

    if (confirmed == true && context.mounted) {
      final ref = ProviderScope.containerOf(context);
      try {
        final err = await ref
            .read(postedItemsProvider.notifier)
            .deleteItem(item.id);
        if (err == null && context.mounted) {
          // Force refresh lists so the deleted item disappears immediately
          ref.invalidate(postedItemsProvider);
          ref.invalidate(itemListProvider);
          ref.invalidate(itemsByTypeProvider(ItemType.lost));
          ref.invalidate(itemsByTypeProvider(ItemType.found));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Item deleted successfully'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(err ?? 'Failed to delete item')),
                ],
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Failed to delete item'),
                ],
              ),
              backgroundColor: AppTheme.errorRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
          );
        }
      }
    }
  }

  Map<String, List<PostedItem>> _groupItemsByStatus(List<PostedItem> items) {
    final Map<String, List<PostedItem>> grouped = {};

    for (final item in items) {
      final status = item.status.name.toLowerCase();
      grouped.putIfAbsent(status, () => []).add(item);
    }

    // Sort items within each group by creation date (newest first)
    grouped.forEach((status, items) {
      items.sort(
        (a, b) =>
            DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)),
      );
    });

    // Return in preferred order
    final orderedGroups = <String, List<PostedItem>>{};
    const preferredOrder = [
      'open',
      'matched',
      'returned',
      'closed',
      'unclaimed',
    ];

    for (final status in preferredOrder) {
      if (grouped.containsKey(status)) {
        orderedGroups[status] = grouped[status]!;
      }
    }

    // Add any remaining statuses
    grouped.forEach((status, items) {
      if (!orderedGroups.containsKey(status)) {
        orderedGroups[status] = items;
      }
    });

    return orderedGroups;
  }
}

// Local _ActionButton removed in favor of shared ActionSheetButton

// CTA removed (FAB already exists)

class _LostAndFoundScreenState extends ConsumerState<LostAndFoundScreen>
    with SingleTickerProviderStateMixin {
  // Shared sizing for item cards in horizontal lists (match ItemCard default)
  static const double itemCardWidth = 190;
  // header height is handled by ItemCard's default
  static const double itemHorizontalGap = 12;
  String _searchQuery = '';
  ItemStatus? _filterStatus;
  final TextEditingController _searchController = TextEditingController();

  // Collapsible categories state - "Recently Posted Items" expanded by default
  final Set<String> _expandedCategories = {'Recently Posted Items'};

  // TabController to track active tab
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final int tabLength = 3;
    _tabController = TabController(
      length: tabLength,
      initialIndex: widget.initialTabIndex.clamp(0, tabLength - 1),
      vsync: this,
    );
    _tabController.addListener(() {
      setState(() {}); // Rebuild to show/hide FAB
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendedAsync = ref.watch(recommendedItemsProvider);
    // Check if current tab is "My Posts" (index 2)
    final bool isMyPostsTab = _tabController.index == 2;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(170),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16), // Top margin
              // Top Bar with Search Bar Inside
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryBlue,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppTheme.radiusXLarge),
                      bottomRight: Radius.circular(AppTheme.radiusXLarge),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingL,
                    vertical: AppTheme.spacingM,
                  ),
                  child: Column(
                    children: [
                      // Search Bar Inside Blue Container
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusLarge,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingM,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: AppTheme.textGray,
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                textInputAction: TextInputAction.search,
                                onChanged: (v) {
                                  setState(() {
                                    _searchQuery = v.toLowerCase();
                                  });
                                },
                                onSubmitted: (v) {
                                  setState(() {
                                    _searchQuery = v.trim().toLowerCase();
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search lost or found items...',
                                  hintStyle: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                ),
                                style: AppTheme.bodyMedium,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppTheme.textGray,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _searchController.clear();
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tab Bar - Enhanced Segmented Control
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.lightPanel,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                    boxShadow: AppTheme.elevatedShadow,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: false,
                    labelColor: Colors.white,
                    labelStyle: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    unselectedLabelColor: AppTheme.textGray,
                    unselectedLabelStyle: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textGray,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.1,
                    ),
                    indicator: BoxDecoration(
                      color: AppTheme.primaryBlue,
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusMedium,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Found',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline_rounded, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Lost',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 16),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'My Posts',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _FoundTab(
            searchQuery: _searchQuery,
            filterStatus: _filterStatus,
            recommendedAsync: recommendedAsync,
            expandedCategories: _expandedCategories,
            onToggleCategory: (title) {
              setState(() {
                if (_expandedCategories.contains(title)) {
                  _expandedCategories.remove(title);
                } else {
                  _expandedCategories.add(title);
                }
              });
            },
          ),
          _LostTab(
            searchQuery: _searchQuery,
            filterStatus: _filterStatus,
            recommendedAsync: recommendedAsync,
            expandedCategories: _expandedCategories,
            onToggleCategory: (title) {
              setState(() {
                if (_expandedCategories.contains(title)) {
                  _expandedCategories.remove(title);
                } else {
                  _expandedCategories.add(title);
                }
              });
            },
          ),
          const _MyPostsTab(),
        ],
      ),
      floatingActionButton: isMyPostsTab
          ? Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldenAccent.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PostItemScreen()),
                ),
                backgroundColor: AppTheme.primaryBlue,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 20),
                label: const Text(
                  'Post Item',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNetflixList(
    List<Item> items,
    AsyncValue<List<MatchScoreItem>> recommendedAsync,
    Set<String> expandedCategories,
    Function(String) onToggleCategory,
  ) {
    if (items.isEmpty) return _buildEmptyState();
    final now = DateTime.now();
    final recentItems =
        items.where((item) {
          final createdAt = DateTime.tryParse(item.createdAt);
          return createdAt != null && now.difference(createdAt).inDays <= 5;
        }).toList()..sort(
          (a, b) => DateTime.parse(
            b.createdAt,
          ).compareTo(DateTime.parse(a.createdAt)),
        );

    final Map<String, List<Item>> categoryMap = {
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
      padding: const EdgeInsets.only(
        bottom: AppTheme.spacingXL,
        top: AppTheme.spacingL,
        left: 20,
        right: 20,
      ),
      itemCount: categoryMap.length,
      itemBuilder: (context, index) {
        final title = categoryMap.keys.elementAt(index);
        final items = categoryMap[title]!;
        if (items.isEmpty) return const SizedBox.shrink();
        final isExpanded = expandedCategories.contains(title);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == categoryMap.length - 1 ? 0 : AppTheme.spacingXXL,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Collapsible Category Header
              InkWell(
                onTap: () {
                  onToggleCategory(title);
                },
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SectionHeader(
                              title: title,
                              icon: _getCategorySectionIcon(title),
                            ),
                          ),
                          const SizedBox(width: AppTheme.spacingS),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: AppTheme.mediumAnimation,
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingM),
                      Divider(height: 1, thickness: 1, color: Colors.grey[200]),
                    ],
                  ),
                ),
              ),
              // Collapsible Horizontal Scrollable Cards
              AnimatedSize(
                duration: AppTheme.mediumAnimation,
                curve: Curves.easeInOut,
                child: isExpanded
                    ? SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.zero,
                          itemExtent: itemCardWidth + itemHorizontalGap,
                          itemCount: items.length,
                          itemBuilder: (context, idx) {
                            final rightPad = (idx == items.length - 1)
                                ? 0.0
                                : itemHorizontalGap;
                            return Padding(
                              padding: EdgeInsets.only(right: rightPad),
                              child: _buildNetflixItemCard(context, items[idx]),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Get icon for category SECTION headers (e.g., "Recently Posted Items", "Electronic")
  /// Different from item category icons - this is for UI section headers
  IconData _getCategorySectionIcon(String categoryName) {
    switch (categoryName) {
      case 'Recently Posted Items':
        return Icons.schedule_rounded;
      case 'Electronic':
        return Icons.devices_other;
      case 'Document':
        return Icons.description;
      case 'Accessories':
        return Icons.watch;
      case 'ID and Cards':
        return Icons.badge;
      case 'Clothing':
        return Icons.checkroom;
      case 'Bag and Pouches':
        return Icons.backpack;
      case 'Personal Item':
        return Icons.assignment_ind;
      case 'School Supplies':
        return Icons.library_books;
      case 'Others Types':
        return Icons.category;
      default:
        return Icons.inventory_2;
    }
  }

  Widget _buildNetflixItemCard(BuildContext context, Item item) {
    return ItemCard(
      item: item,
      cardWidth: itemCardWidth,
      radius: AppTheme.radiusXXLarge,
      borderOpacity: 0.06,
      borderWidth: 0.75,
      onTap: () => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => ItemDetailsModal(itemId: item.id, type: item.type),
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty || _filterStatus != null) {
      return EmptyState(
        icon: Icons.search_off,
        title: 'No items found',
        subtitle: 'Try adjusting your search or filters',
        buttonLabel: 'Clear Filters',
        onButtonPressed: () {
          setState(() {
            _searchQuery = '';
            _filterStatus = null;
          });
        },
        padding: const EdgeInsets.all(AppTheme.spacingXL),
      );
    }

    return const EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No items available yet',
      subtitle: 'Items that are lost or found will appear here',
      padding: EdgeInsets.all(AppTheme.spacingXL),
    );
  }
}

class _ShimmerLoadingPlaceholder extends StatelessWidget {
  const _ShimmerLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return _buildLoadingState();
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppTheme.spacingL, bottom: 120),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingXL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppTheme.spacingS),
                child: LoadingSectionHeaderPlaceholder(),
              ),
              const LoadingHorizontalCardsPlaceholder(),
            ],
          ),
        );
      },
    );
  }
}
