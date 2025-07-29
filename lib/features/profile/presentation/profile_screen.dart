import 'package:navistfind/core/constants.dart';
import 'package:navistfind/features/auth/application/auth_provider.dart';
import 'package:navistfind/features/item/presentation/ai_match_card.dart';
import 'package:navistfind/features/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/item/presentation/matched_items_modal.dart';
import 'package:navistfind/features/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/post-item/presentation/edit_item_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Filter state provider
final itemFilterProvider = StateProvider<String>((ref) => 'All');

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    ref.read(logoutStateProvider.notifier).state = true;
    final error = await ref.read(authProvider).logout();
    ref.read(logoutStateProvider.notifier).state = false;

    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logout Successful'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
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

  List<PostedItem> _getFilteredItems(List<PostedItem> items, String filter) {
    switch (filter) {
      case 'Lost':
        return items.where((item) => item.type == ItemType.lost).toList();
      case 'Found':
        return items.where((item) => item.type == ItemType.found).toList();
      default:
        return items;
    }
  }

  // NEW HELPERS
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PostedItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final error = await ref
          .read(postedItemsProvider.notifier)
          .deleteItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Item deleted'),
            backgroundColor: error == null ? Colors.blue : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileInfoProvider);
    final postedItemsAsyncValue = ref.watch(postedItemsProvider);
    final currentFilter = ref.watch(itemFilterProvider);
    final isPendingLogout = ref.watch(logoutStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF1C2A40),
      body: SafeArea(
        child: profileAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),
          data: (profile) => postedItemsAsyncValue.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading items: $error',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            data: (postedItems) {
              final filteredItems = _getFilteredItems(
                postedItems,
                currentFilter,
              );
              // Sort: matched items first, then by most recent
              filteredItems.sort((a, b) {
                final aHasMatch =
                    (a.matchedItem.highestBest ?? a.matchedItem.lowerBest) !=
                    null;
                final bHasMatch =
                    (b.matchedItem.highestBest ?? b.matchedItem.lowerBest) !=
                    null;
                if (aHasMatch != bHasMatch) {
                  return bHasMatch ? 1 : -1; // Show matched items first
                }
                final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(2000);
                final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(2000);
                return bDate.compareTo(aDate); // Newest first
              });
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 36, bottom: 24),
                            decoration: const BoxDecoration(
                              color: Color(0xFF1C2A40),
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(height: 8),
                                Hero(
                                  tag: 'profile_avatar',
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 48,
                                      backgroundColor: Colors.white,
                                      child: const Icon(
                                        Icons.person,
                                        size: 48,
                                        color: Color(0xFF1C2A40),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  profile.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profile.email,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFFF4B431),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Total Posted Items: ',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        postedItems.length.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFFF4B431),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 36,
                            right: 24,
                            child: IconButton(
                              icon: isPendingLogout
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                              onPressed: isPendingLogout
                                  ? null
                                  : () => _logout(context, ref),
                              tooltip: 'Logout',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Items Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                      child: Row(
                        children: const [
                          Text(
                            'Your Posted Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Items List or Empty State
                  if (filteredItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: Colors.white24,
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, idx) => _buildItemCard(filteredItems[idx]),
                          childCount: filteredItems.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // Item Card
  Widget _buildItemCard(PostedItem item) {
    final bestMatch =
        item.matchedItem.highestBest ?? item.matchedItem.lowerBest;
    final hasMatch = bestMatch != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => showItemDetailsModal(context, item.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    color: const Color(0xFFF4B431),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1C2A40),
                          ),
                        ),
                        const SizedBox(height: 4),
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
                                  fontSize: 13,
                                  color: Color(0xFF1C2A40),
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
                              _formatDate(item.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF1C2A40),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Edit/Delete buttons
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF1C2A40)),
                        tooltip: 'Edit',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditItemScreen(item: item),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, ref, item),
                      ),
                    ],
                  ),
                ],
              ),
              // AI Match Score Section (future enhancement)
            ],
          ),
        ),
      ),
    );
  }
}
