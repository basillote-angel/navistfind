import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/category.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'claim_item.dart';
import 'matched_items_modal.dart';
import 'ai_match_card.dart';
import 'package:navistfind/features/lost_found/post-item/presentation/edit_item_screen.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/lost_found/item/domain/models/item.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_helpers.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';

void showItemDetailsModal(BuildContext context, int itemId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ItemDetailsModal(itemId: itemId),
  );
}

class ItemDetailsModal extends ConsumerWidget {
  final int itemId;
  final ItemType? type;
  const ItemDetailsModal({super.key, required this.itemId, this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = type != null
        ? ref.watch(itemDetailsWithTypeProvider((id: itemId, type: type!)))
        : ref.watch(itemDetailsProvider(itemId));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.all(24),

      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = MediaQuery.of(context).size.height * 0.60;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: itemAsync.when(
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => SizedBox(
                      height: 200,
                      child: Center(child: Text('Error: $e')),
                    ),
                    data: (item) {
                      // Note: profileInfoProvider was previously used for gating actions.
                      // We keep the fetch lightweight here in case future logic needs it.
                      // final meAsync = ref.watch(profileInfoProvider);
                      //Format helpers
                      final dateFmt = DateFormat('MMM d, yyyy');
                      final dtLostFound = DateTime.parse(item.date);
                      final createdAt = DateTime.parse(
                        item.created_at,
                      ); // ensure this is the correct field
                      final fullDateTimeFormat = DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      );

                      final lfLabel = item.type == ItemType.found
                          ? 'Date Found'
                          : 'Date Lost';

                      // Notice text depending on type
                      final noticeLost =
                          'If you have found this item, please turn it over to the admin office immediately. Your cooperation helps reunite lost items with their owners.';
                      final noticeFound =
                          'Please bring valid proof of ownership when claiming this item at the admin office.';
                      final noticeText = item.type == ItemType.found
                          ? noticeFound
                          : noticeLost;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Header with Category Icon and Gradient
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: AppTheme.cardGradient,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Category Icon Container
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMedium,
                                    ),
                                  ),
                                  child: Icon(
                                    getCategoryIcon(item.category),
                                    color: AppTheme.primaryBlue,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Title and Status
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: AppTheme.heading3.copyWith(
                                          color: AppTheme.darkText,
                                          fontSize: 20,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          // Type Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: item.type == ItemType.found
                                                  ? AppTheme.successGreen
                                                        .withOpacity(0.15)
                                                  : AppTheme.goldenAccent
                                                        .withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                            ),
                                            child: Text(
                                              item.type == ItemType.found
                                                  ? 'Found'
                                                  : 'Lost',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    item.type == ItemType.found
                                                    ? AppTheme.successGreen
                                                    : AppTheme.warningOrange,
                                              ),
                                            ),
                                          ),
                                          // Status Badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                item.status,
                                              ).withOpacity(0.15),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                            ),
                                            child: Text(
                                              _getStatusLabel(item.status),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: _getStatusColor(
                                                  item.status,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Consumer(
                                  builder: (context, ref, _) {
                                    final meAsync = ref.watch(
                                      profileInfoProvider,
                                    );
                                    return meAsync.when(
                                      loading: () => const SizedBox.shrink(),
                                      error: (_, __) => const SizedBox.shrink(),
                                      data: (me) {
                                        final isPoster =
                                            (item.ownerId == me.id) ||
                                            (item.finderId == me.id) ||
                                            (item.posterId == me.id);
                                        if (!isPoster) {
                                          return const SizedBox.shrink();
                                        }
                                        // Check if item can be edited/deleted based on status
                                        final canEditDelete =
                                            item.status == ItemStatus.open;

                                        return PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'edit') {
                                              if (!canEditDelete) {
                                                _showCannotEditDialog(
                                                  context,
                                                  item.status,
                                                );
                                                return;
                                              }
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditItemScreen(
                                                        item: PostedItem(
                                                          id: item.id,
                                                          ownerId: item.ownerId,
                                                          finderId:
                                                              item.finderId,
                                                          name: item.title,
                                                          category: item
                                                              .category
                                                              .name,
                                                          description:
                                                              item.description,
                                                          status: item.status,
                                                          type: item.type,
                                                          location:
                                                              item.location,
                                                          lostFoundDate:
                                                              item.date,
                                                          createdAt:
                                                              item.createdAt,
                                                          updatedAt:
                                                              item.updatedAt,
                                                          matchedItem:
                                                              BestMatchedItem(
                                                                highestBest:
                                                                    null,
                                                                lowerBest: null,
                                                              ),
                                                        ),
                                                      ),
                                                ),
                                              );
                                            } else if (value == 'delete') {
                                              if (!canEditDelete) {
                                                _showCannotDeleteDialog(
                                                  context,
                                                  item.status,
                                                );
                                                return;
                                              }
                                              final confirmed =
                                                  await _showDeleteConfirmationDialog(
                                                    context,
                                                    item,
                                                  );
                                              if (confirmed == true) {
                                                try {
                                                  final err = await ref
                                                      .read(
                                                        postedItemsProvider
                                                            .notifier,
                                                      )
                                                      .deleteItem(item.id);
                                                  if (err == null) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: const Row(
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .check_circle,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Item deleted successfully',
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor:
                                                              AppTheme
                                                                  .successGreen,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  AppTheme
                                                                      .radiusMedium,
                                                                ),
                                                          ),
                                                          duration:
                                                              const Duration(
                                                                seconds: 3,
                                                              ),
                                                        ),
                                                      );
                                                      Navigator.pop(context);
                                                    }
                                                  } else {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Row(
                                                            children: [
                                                              const Icon(
                                                                Icons
                                                                    .error_outline,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                  err,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          backgroundColor:
                                                              AppTheme.errorRed,
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  AppTheme
                                                                      .radiusMedium,
                                                                ),
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: const Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .error_outline,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            SizedBox(width: 8),
                                                            Text(
                                                              'Failed to delete item',
                                                            ),
                                                          ],
                                                        ),
                                                        backgroundColor:
                                                            AppTheme.errorRed,
                                                        behavior:
                                                            SnackBarBehavior
                                                                .floating,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                AppTheme
                                                                    .radiusMedium,
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            PopupMenuItem<String>(
                                              value: 'edit',
                                              enabled: canEditDelete,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: canEditDelete
                                                        ? AppTheme.darkText
                                                        : AppTheme.textGray,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Edit',
                                                          style: TextStyle(
                                                            color: canEditDelete
                                                                ? AppTheme
                                                                      .darkText
                                                                : AppTheme
                                                                      .textGray,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (!canEditDelete)
                                                          Text(
                                                            _getEditDisabledReason(
                                                              item.status,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: AppTheme
                                                                  .textGray,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            PopupMenuItem<String>(
                                              value: 'delete',
                                              enabled: canEditDelete,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.delete_outline,
                                                    size: 18,
                                                    color: canEditDelete
                                                        ? AppTheme.errorRed
                                                        : AppTheme.textGray,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          'Delete',
                                                          style: TextStyle(
                                                            color: canEditDelete
                                                                ? AppTheme
                                                                      .errorRed
                                                                : AppTheme
                                                                      .textGray,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                        if (!canEditDelete)
                                                          Text(
                                                            _getDeleteDisabledReason(
                                                              item.status,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: AppTheme
                                                                  .textGray,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Item Information Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusLarge,
                              ),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withOpacity(0.1),
                                width: 1,
                              ),
                              boxShadow: AppTheme.elevatedShadow,
                            ),
                            child: Column(
                              children: [
                                _enhancedInfoRow(
                                  icon: Icons.category_outlined,
                                  label: 'Category',
                                  value: item.category.label,
                                ),
                                const Divider(height: 20, thickness: 0.5),
                                _enhancedInfoRow(
                                  icon: Icons.location_on_outlined,
                                  label: 'Location',
                                  value: item.location,
                                ),
                                const Divider(height: 20, thickness: 0.5),
                                _enhancedInfoRow(
                                  icon: item.type == ItemType.found
                                      ? Icons.check_circle_outline
                                      : Icons.search_off_outlined,
                                  label: lfLabel,
                                  value: dateFmt.format(dtLostFound),
                                ),
                                const Divider(height: 20, thickness: 0.5),
                                _enhancedInfoRow(
                                  icon: Icons.schedule_outlined,
                                  label: 'Date Posted',
                                  value: fullDateTimeFormat.format(createdAt),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Notice (hide if the viewer is the poster of this item)
                          Builder(
                            builder: (context) {
                              final meAsync = ref.watch(profileInfoProvider);
                              return meAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (me) {
                                  final postedByMe =
                                      (item.ownerId == me.id) ||
                                      (item.finderId == me.id) ||
                                      (item.posterId == me.id);
                                  if (postedByMe) {
                                    return const SizedBox.shrink();
                                  }
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppTheme.goldenAccent.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                      border: Border.all(
                                        color: AppTheme.goldenAccent
                                            .withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: AppTheme.warningOrange,
                                          size: 22,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Notice',
                                                style: AppTheme.bodyMedium
                                                    .copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: AppTheme.darkText,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                noticeText,
                                                style: AppTheme.bodySmall
                                                    .copyWith(
                                                      color: AppTheme.darkText
                                                          .withOpacity(0.8),
                                                      height: 1.4,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SizedBox(height: 24),

                          // Tip banner: show if no matches or top score < 0.60 (owner-only)
                          Builder(
                            builder: (context) {
                              final meAsync = ref.watch(profileInfoProvider);
                              return meAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (me) {
                                  final isOwner =
                                      (item.type == ItemType.lost &&
                                          (item.ownerId == me.id ||
                                              item.posterId == me.id)) ||
                                      (item.type == ItemType.found &&
                                          (item.finderId == me.id ||
                                              item.posterId == me.id));
                                  if (!isOwner) return const SizedBox.shrink();

                                  final matchesAsync = ref.watch(
                                    matchesItemsProvider(item.id),
                                  );
                                  return matchesAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (matches) {
                                      final top = matches.isEmpty
                                          ? 0.0
                                          : matches
                                                .map((m) => m.score)
                                                .reduce(
                                                  (a, b) => a > b ? a : b,
                                                );
                                      final showTip =
                                          matches.isEmpty || top < 0.60;
                                      if (!showTip) {
                                        return const SizedBox.shrink();
                                      }
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: AppTheme.softYellow,
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.goldenAccent
                                                .withOpacity(0.5),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.tips_and_updates_outlined,
                                              color: AppTheme.warningOrange,
                                              size: 22,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Improve Your Match',
                                                    style: AppTheme.bodyMedium
                                                        .copyWith(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color:
                                                              AppTheme.darkText,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'No strong matches yet. Add color/brand or unique marks to improve results.',
                                                    style: AppTheme.bodySmall
                                                        .copyWith(
                                                          color: AppTheme
                                                              .darkText
                                                              .withOpacity(0.8),
                                                          height: 1.4,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        EditItemScreen(
                                                          item: PostedItem(
                                                            id: item.id,
                                                            ownerId:
                                                                item.ownerId,
                                                            finderId:
                                                                item.finderId,
                                                            name: item.title,
                                                            category: item
                                                                .category
                                                                .name,
                                                            description: item
                                                                .description,
                                                            status: item.status,
                                                            type: item.type,
                                                            location:
                                                                item.location,
                                                            lostFoundDate:
                                                                item.date,
                                                            createdAt:
                                                                item.createdAt,
                                                            updatedAt:
                                                                item.updatedAt,
                                                            matchedItem:
                                                                BestMatchedItem(
                                                                  highestBest:
                                                                      null,
                                                                  lowerBest:
                                                                      null,
                                                                ),
                                                          ),
                                                        ),
                                                  ),
                                                );
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppTheme.warningOrange,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                              ),
                                              child: const Text(
                                                'Add details',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),

                          // AI Matches section (owner-only for lost items; hidden for found items)
                          Builder(
                            builder: (context) {
                              final meAsync = ref.watch(profileInfoProvider);
                              return meAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (me) {
                                  final canShow =
                                      (item.type == ItemType.lost &&
                                          item.ownerId == me.id) ||
                                      (item.type == ItemType.found &&
                                          item.finderId == me.id);
                                  if (!canShow) return const SizedBox.shrink();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryBlue
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                            ),
                                            child: Icon(
                                              Icons.auto_awesome,
                                              color: AppTheme.primaryBlue,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'AI Matches',
                                            style: AppTheme.heading4.copyWith(
                                              fontSize: 17,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Builder(
                                        builder: (context) {
                                          final matchesAsync = ref.watch(
                                            matchesItemsProvider(item.id),
                                          );
                                          return matchesAsync.when(
                                            loading: () => const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 8,
                                              ),
                                              child: SizedBox(
                                                height: 24,
                                                width: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                            ),
                                            error: (e, _) => Text(
                                              'Could not load matches',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            data: (matches) {
                                              if (matches.isEmpty) {
                                                return Text(
                                                  'No matches yet. We\'ll notify you when we find potential matches.',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                );
                                              }
                                              final best = matches.reduce(
                                                (a, b) =>
                                                    a.score >= b.score ? a : b,
                                              );
                                              return Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 8,
                                                        ),
                                                    child: AiMatchCard(
                                                      score: best.score,
                                                      item: best.item,
                                                      onTap: () =>
                                                          showItemDetailsModal(
                                                            context,
                                                            best.item!.id,
                                                          ),
                                                    ),
                                                  ),
                                                  Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: TextButton.icon(
                                                      onPressed: () {
                                                        showModalBottomSheet(
                                                          context: context,
                                                          isScrollControlled:
                                                              true,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          builder: (_) =>
                                                              MatchedItemsModal(
                                                                itemId: item.id,
                                                              ),
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.list_alt,
                                                      ),
                                                      label: const Text(
                                                        'View all matches',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                          // Action Buttons (found only)
                          if (item.type == ItemType.found) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.lightPanel,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusLarge,
                                ),
                                border: Border.all(
                                  color: AppTheme.primaryBlue.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Got it. We\'ll refine your matches.',
                                            ),
                                            backgroundColor: AppTheme.textGray,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusMedium,
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'Not mine',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.darkText,
                                        side: BorderSide(
                                          color: AppTheme.primaryBlue
                                              .withOpacity(0.3),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ClaimItemPage(itemId: item.id),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        'This is mine',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryBlue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppTheme.radiusMedium,
                                          ),
                                        ),
                                        elevation: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Enhanced info row with icon
  Widget _enhancedInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          ),
          child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Get status color
  Color _getStatusColor(ItemStatus status) {
    switch (status) {
      case ItemStatus.open:
        return AppTheme.primaryBlue;
      case ItemStatus.matched:
        return AppTheme.goldenAccent;
      case ItemStatus.returned:
        return AppTheme.successGreen;
      case ItemStatus.closed:
        return AppTheme.textGray;
      case ItemStatus.unclaimed:
        return AppTheme.errorRed;
    }
  }

  /// Get status label
  String _getStatusLabel(ItemStatus status) {
    switch (status) {
      case ItemStatus.open:
        return 'Open';
      case ItemStatus.matched:
        return 'Matched';
      case ItemStatus.returned:
        return 'Returned';
      case ItemStatus.closed:
        return 'Closed';
      case ItemStatus.unclaimed:
        return 'Unclaimed';
    }
  }

  /// Get edit disabled reason
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

  /// Get delete disabled reason
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

  /// Show dialog when edit is not allowed
  void _showCannotEditDialog(BuildContext context, ItemStatus status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 24),
            const SizedBox(width: 12),
            const Text('Cannot Edit Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This item cannot be edited because it has already been ${_getStatusLabel(status).toLowerCase()}.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.softYellow,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    color: AppTheme.warningOrange,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only items with "Open" status can be edited.',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog when delete is not allowed
  void _showCannotDeleteDialog(BuildContext context, ItemStatus status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.errorRed,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text('Cannot Delete Item'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This item cannot be deleted because it has already been ${_getStatusLabel(status).toLowerCase()}.',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.errorRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only items with "Open" status can be deleted.',
                      style: AppTheme.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Show enhanced delete confirmation dialog
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Item item) {
    return showDialog<bool>(
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
              child: Icon(
                Icons.delete_outline,
                color: AppTheme.errorRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Text('Delete Item?')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              'This action cannot be undone. The item will be permanently removed from the system.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textGray),
            ),
          ],
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
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
