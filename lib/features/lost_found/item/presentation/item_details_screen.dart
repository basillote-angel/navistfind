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

void showItemDetailsModal(BuildContext context, int itemId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ItemDetailsModal(itemId: itemId),
  );
}

class ItemDetailsModal extends ConsumerWidget {
  final int itemId;
  const ItemDetailsModal({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemDetailsProvider(itemId));
    final theme = Theme.of(context);

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
                      final dtLostFound = DateTime.parse(item.lost_found_date);
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
                          'If you locate this item, please notify the admin office immediately.';
                      final noticeFound =
                          'Please bring valid proof of ownership when claiming this item at the admin office.';
                      final noticeText = item.type == ItemType.found
                          ? noticeFound
                          : noticeLost;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title with overflow menu
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Consumer(
                                builder: (context, ref, _) {
                                  final meAsync = ref.watch(
                                    profileInfoProvider,
                                  );
                                  return meAsync.when(
                                    loading: () => PopupMenuButton<String>(
                                      onSelected: (_) {},
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(
                                          value: 'message_admin',
                                          child: Text('Message Admin'),
                                        ),
                                      ],
                                    ),
                                    error: (_, __) => PopupMenuButton<String>(
                                      onSelected: (_) {},
                                      itemBuilder: (ctx) => const [
                                        PopupMenuItem(
                                          value: 'message_admin',
                                          child: Text('Message Admin'),
                                        ),
                                      ],
                                    ),
                                    data: (me) {
                                      final isPoster =
                                          (item.owner_id == me.id) ||
                                          (item.finder_id == me.id);
                                      return PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'message_admin') {
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Message sent to Admin.',
                                                ),
                                              ),
                                            );
                                          } else if (value == 'edit') {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditItemScreen(
                                                  item: PostedItem(
                                                    id: item.id,
                                                    ownerId: item.owner_id,
                                                    finderId: item.finder_id,
                                                    name: item.name,
                                                    category:
                                                        item.category.name,
                                                    description:
                                                        item.description,
                                                    status: item.status,
                                                    type: item.type,
                                                    location: item.location,
                                                    lostFoundDate:
                                                        item.lost_found_date,
                                                    createdAt: item.created_at,
                                                    updatedAt: item.updated_at,
                                                    matchedItem:
                                                        BestMatchedItem(
                                                          highestBest: null,
                                                          lowerBest: null,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else if (value == 'delete') {
                                            final confirmed =
                                                await showDialog<bool>(
                                                  context: context,
                                                  builder: (ctx) => AlertDialog(
                                                    title: const Text(
                                                      'Delete item?',
                                                    ),
                                                    content: const Text(
                                                      'This action cannot be undone.',
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              false,
                                                            ),
                                                        child: const Text(
                                                          'Cancel',
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                              ctx,
                                                              true,
                                                            ),
                                                        child: const Text(
                                                          'Delete',
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                            if (confirmed == true) {
                                              try {
                                                await ref
                                                    .read(
                                                      profileServiceProvider,
                                                    )
                                                    .deleteItem(item.id);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Item deleted',
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF2E7D32,
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                                // Close details
                                                Navigator.pop(context);
                                              } catch (e) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to delete item',
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFFC62828,
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (ctx) {
                                          final items =
                                              <PopupMenuEntry<String>>[
                                                const PopupMenuItem(
                                                  value: 'message_admin',
                                                  child: Text('Message Admin'),
                                                ),
                                              ];
                                          if (isPoster) {
                                            items.addAll(const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Edit'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Delete'),
                                              ),
                                            ]);
                                          }
                                          return items;
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Info rows
                          _infoRow(
                            'Type',
                            item.type == ItemType.found ? 'Found' : 'Lost',
                          ),
                          _infoRow('Category', item.category.label),
                          _infoRow('Location', item.location),
                          _infoRow(lfLabel, dateFmt.format(dtLostFound)),
                          _infoRow(
                            'Date Posted',
                            fullDateTimeFormat.format(createdAt),
                          ),
                          const Divider(height: 28),

                          // Notice (hide if the viewer is the poster of this item)
                          Builder(
                            builder: (context) {
                              final meAsync = ref.watch(profileInfoProvider);
                              return meAsync.when(
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                                data: (me) {
                                  final postedByMe =
                                      (item.owner_id == me.id) ||
                                      (item.finder_id == me.id);
                                  if (postedByMe)
                                    return const SizedBox.shrink();
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Notice:',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(noticeText),
                                    ],
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
                                          item.owner_id == me.id) ||
                                      (item.type == ItemType.found &&
                                          item.finder_id == me.id);
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
                                      if (!showTip)
                                        return const SizedBox.shrink();
                                      return Container(
                                        margin: const EdgeInsets.only(
                                          bottom: 12,
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7E6),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFFFE0A3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF8A6D3B),
                                            ),
                                            const SizedBox(width: 8),
                                            const Expanded(
                                              child: Text(
                                                'No strong matches yet. Add color/brand or unique marks to improve results.',
                                                style: TextStyle(
                                                  color: Color(0xFF8A6D3B),
                                                ),
                                              ),
                                            ),
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
                                                                item.owner_id,
                                                            finderId:
                                                                item.finder_id,
                                                            name: item.name,
                                                            category: item
                                                                .category
                                                                .name,
                                                            description: item
                                                                .description,
                                                            status: item.status,
                                                            type: item.type,
                                                            location:
                                                                item.location,
                                                            lostFoundDate: item
                                                                .lost_found_date,
                                                            createdAt:
                                                                item.created_at,
                                                            updatedAt:
                                                                item.updated_at,
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
                                              child: const Text('Add details'),
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
                                          item.owner_id == me.id) ||
                                      (item.type == ItemType.found &&
                                          item.finder_id == me.id);
                                  if (!canShow) return const SizedBox.shrink();

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AI Matches',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
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

                          // Buttons (found only)
                          if (item.type == ItemType.found) ...[
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Got it. We\'ll refine your matches.',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Text('Not mine'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ClaimItemPage(itemId: item.id),
                                        ),
                                      );
                                    },
                                    child: const Text('This is mine'),
                                  ),
                                ),
                              ],
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

  /// Utility: single two‑column row
  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}
