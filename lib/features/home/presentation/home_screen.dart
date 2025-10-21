import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_category_list.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/features/navigate/presentation/campus_map_screen.dart';
import 'package:navistfind/features/navigate/presentation/ar_transition_screen.dart';
import 'package:latlong2/latlong.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final recommendedAsync = ref.watch(recommendedItemsProvider);
    final itemsAsync = ref.watch(itemListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NavistFind'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            tooltip: 'Notifications',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const PostItemScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          // Hero actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Post Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PostItemScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickChip(
                        context: context,
                        icon: Icons.search,
                        label: 'Lost something?',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoryItemsView(
                                title: 'Lost Items',
                                filterCategory: null,
                                showRecentOnly: false,
                                recommendedOnly: false,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildQuickChip(
                        context: context,
                        icon: Icons.handshake_outlined,
                        label: 'Found something?',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CategoryItemsView(
                                title: 'Found Items',
                                filterCategory: null,
                                showRecentOnly: false,
                                recommendedOnly: false,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSectionHeader('Campus navigation'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildNavCard(
                        context: context,
                        icon: Icons.map_rounded,
                        title: 'Open Map',
                        subtitle: 'Explore campus locations',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CampusMapScreen(),
                            ),
                          );
                        },
                      ),
                      _buildNavCard(
                        context: context,
                        icon: Icons.assistant_direction_rounded,
                        title: 'Start AR',
                        subtitle: 'AR guidance to destination',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ARTransitionScreen(
                                destination: const LatLng(0, 0),
                                buildingDescription: '',
                                rooms: const [],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Recommended for you
          SliverToBoxAdapter(child: _buildSectionHeader('Recommended for you')),
          SliverToBoxAdapter(
            child: recommendedAsync.when(
              data: (matches) {
                final items = matches
                    .map((m) => m.item)
                    .whereType<Item>()
                    .toList();
                if (items.isEmpty) return const SizedBox.shrink();
                return _buildHorizontalItems(context, items);
              },
              loading: () => _buildHorizontalSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Categories grid
          SliverToBoxAdapter(child: _buildSectionHeader('Categories')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate(
                ItemCategory.values.map((c) {
                  return _buildCategoryCard(context, c);
                }).toList(),
              ),
            ),
          ),

          // Newest items
          SliverToBoxAdapter(child: _buildSectionHeader('Newest items')),
          SliverToBoxAdapter(
            child: itemsAsync.when(
              data: (items) {
                final sorted = [...items]
                  ..sort(
                    (a, b) => DateTime.parse(
                      b.created_at,
                    ).compareTo(DateTime.parse(a.created_at)),
                  );
                return _buildHorizontalItems(context, sorted.take(12).toList());
              },
              loading: () => _buildHorizontalSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Helpful info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Helpful info'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildInfoCard(
                        context: context,
                        icon: Icons.verified_user_outlined,
                        title: 'How claiming works',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/help/claiming'),
                      ),
                      _buildInfoCard(
                        context: context,
                        icon: Icons.health_and_safety_outlined,
                        title: 'Safety tips',
                        onTap: () =>
                            Navigator.of(context).pushNamed('/help/safety'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildHorizontalItems(BuildContext context, List<Item> items) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildItemCard(context, items[i]),
      ),
    );
  }

  Widget _buildHorizontalSkeleton() {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Container(
          width: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, Item item) {
    return GestureDetector(
      onTap: () => showItemDetailsModal(context, item.id),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 96,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.06),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Icon(
                getCategoryIcon(item.category),
                size: 44,
                color: Theme.of(context).primaryColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _buildTypeChip(item),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.black54),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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

  Widget _buildTypeChip(Item item) {
    final isLost = item.type.name == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isLost ? Colors.red[100] : Colors.blue[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isLost ? 'Lost' : 'Found',
        style: TextStyle(
          color: isLost ? Colors.red : Colors.blue,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, ItemCategory category) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CategoryItemsView(
              title: category.label,
              filterCategory: category,
              showRecentOnly: false,
              recommendedOnly: false,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Center(
          child: Text(
            category.label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withOpacity(0.20)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final primary = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.20)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: primary)),
          ],
        ),
      ),
    );
  }
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
