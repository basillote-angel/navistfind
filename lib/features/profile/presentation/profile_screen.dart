import 'package:navistfind/features/auth/application/auth_provider.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/edit_item_screen.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:flutter/material.dart';
import 'package:navistfind/widgets/posted_item_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/post_item_screen.dart';
import 'package:navistfind/core/utils/category_utils.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_dialogs.dart';
import 'package:navistfind/widgets/action_sheet_button.dart';
import 'package:navistfind/widgets/section_header.dart';
import 'package:navistfind/core/utils/snackbar_utils.dart';
import 'package:navistfind/widgets/empty_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Icon(Icons.logout, color: AppTheme.errorRed, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Logout?')),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppTheme.textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ref.read(logoutStateProvider.notifier).state = true;
    final error = await ref.read(authProvider).logout();
    ref.read(logoutStateProvider.notifier).state = false;

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      SnackbarUtils.showSuccess(context, 'Logout Successful');
    } else {
      SnackbarUtils.showError(context, error);
    }
  }

  Map<String, int> _getStatistics(List<PostedItem> items) {
    return {
      'total': items.length,
      'open': items.where((i) => i.status == ItemStatus.open).length,
      'matched': items.where((i) => i.status == ItemStatus.matched).length,
      'returned': items.where((i) => i.status == ItemStatus.returned).length,
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PostedItem item,
  ) async {
    final canDelete = item.status == ItemStatus.open;

    if (!canDelete) {
      _showCannotDeleteDialog(context, item.status);
      return;
    }

    final confirmed = await ItemDialogs.showDeleteConfirmationDialog(
      context,
      title: item.name,
    );

    if (confirmed == true) {
      final error = await ref
          .read(postedItemsProvider.notifier)
          .deleteItem(item.id);
      if (context.mounted) {
        if (error == null) {
          SnackbarUtils.showItemDeleted(context);
        } else {
          SnackbarUtils.showError(context, error);
        }
      }
    }
  }

  void _showCannotDeleteDialog(BuildContext context, ItemStatus status) {
    ItemDialogs.showCannotDeleteDialog(context, status);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsyncValue = ref.watch(profileInfoProvider);
    final isPendingLogout = ref.watch(logoutStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.lightGray,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 16),
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
                  child: Row(
                    children: [
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const Spacer(),
                      if (isPendingLogout)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => _logout(context, ref),
                          tooltip: 'Logout',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
        error: (error, stack) => _buildErrorState(error),
        data: (profile) {
          final postedItemsAsyncValue = ref.watch(postedItemsProvider);
          return postedItemsAsyncValue.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            ),
            error: (error, stack) => _buildErrorState(error.toString()),
            data: (postedItems) {
              // All items are lost items (users only post lost items)
              final stats = _getStatistics(postedItems);

              final sortedItems = List<PostedItem>.from(postedItems);
              sortedItems.sort((a, b) {
                final aHasMatch =
                    (a.matchedItem.highestBest ?? a.matchedItem.lowerBest) !=
                    null;
                final bHasMatch =
                    (b.matchedItem.highestBest ?? b.matchedItem.lowerBest) !=
                    null;
                if (aHasMatch != bHasMatch) {
                  return bHasMatch ? 1 : -1;
                }
                final aDate = DateTime.tryParse(a.createdAt) ?? DateTime(2000);
                final bDate = DateTime.tryParse(b.createdAt) ?? DateTime(2000);
                return bDate.compareTo(aDate);
              });

              return CustomScrollView(
                slivers: [
                  // Profile Header Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _buildProfileHeader(
                        context,
                        profile,
                        postedItems.length,
                      ),
                    ),
                  ),
                  // Statistics Cards - 2x2 Grid
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(
                            title: 'Statistics',
                            icon: Icons.analytics_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.report_problem_outlined,
                                  label: 'Items Reported',
                                  value: stats['total']!.toString(),
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.search_rounded,
                                  label: 'Currently Searching',
                                  value: stats['open']!.toString(),
                                  color: AppTheme.warningOrange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.auto_awesome_rounded,
                                  label: 'Potential Matches',
                                  value: stats['matched']!.toString(),
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.check_circle_rounded,
                                  label: 'Successfully Retrieved',
                                  value: stats['returned']!.toString(),
                                  color: AppTheme.successGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Section Header for Items
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: const SectionHeader(
                        title: 'Your Lost Items',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ),
                  // Items List - Horizontal Scroll or Empty State
                  if (sortedItems.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildEmptyState(context, ''),
                      ),
                    )
                  else
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemExtent: 190 + 12, // cardWidth + gap
                            itemCount: sortedItems.length,
                            itemBuilder: (context, idx) {
                              final rightPad = (idx == sortedItems.length - 1)
                                  ? 0.0
                                  : 12.0;
                              return Padding(
                                padding: EdgeInsets.only(right: rightPad),
                                child: PostedItemCard(
                                  postedItem: sortedItems[idx],
                                  cardWidth: 190,
                                  radius: AppTheme.radiusLarge,
                                  onTap: () => showItemDetailsModal(
                                    context,
                                    sortedItems[idx].id,
                                  ),
                                  onLongPress: () => _showItemActionSheet(
                                    context,
                                    sortedItems[idx],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    dynamic profile,
    int totalItems,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryBlue.withOpacity(0.2),
                  width: 3,
                ),
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(profile.name, style: AppTheme.heading2),
          const SizedBox(height: 6),
          Text(
            profile.email,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textGray),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.softYellow,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppTheme.goldenAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_outlined,
                  size: 20,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 10),
                Text(
                  '$totalItems Lost Item${totalItems != 1 ? 's' : ''} Reported',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter) {
    return EmptyState(
      icon: Icons.search_off_outlined,
      title: 'No Lost Items Posted Yet',
      subtitle: 'Start by reporting your first lost item to help us find it',
      buttonLabel: 'Report Lost Item',
      onButtonPressed: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PostItemScreen()));
      },
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
    );
  }

  Widget _buildErrorState(dynamic error) {
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
            Text('Failed to load profile', style: AppTheme.heading4),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Please check your connection and try again',
              style: AppTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(profileInfoProvider);
                ref.invalidate(postedItemsProvider);
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

  void _showItemActionSheet(BuildContext context, PostedItem item) {
    final canEditDelete = item.status == ItemStatus.open;

    showModalBottomSheet(
      context: context,
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
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textGray.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
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
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditItemScreen(item: item),
                          ),
                        );
                      }
                    : () {
                        Navigator.pop(context);
                        _showCannotEditDialog(context, item.status);
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
                        _confirmDelete(context, ref, item);
                      }
                    : () {
                        Navigator.pop(context);
                        ItemDialogs.showCannotDeleteDialog(
                          context,
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

  void _showCannotEditDialog(BuildContext context, ItemStatus status) {
    ItemDialogs.showCannotEditDialog(context, status);
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.elevatedShadow,
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTheme.heading2.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Local _ActionButton removed in favor of shared ActionSheetButton
