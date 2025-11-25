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
import 'package:navistfind/widgets/status_chip.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_dialogs.dart';
import 'package:navistfind/core/utils/snackbar_utils.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';

void showItemDetailsModal(BuildContext context, int itemId) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) => ItemDetailsModal(itemId: itemId),
  );
}

class ItemDetailsModal extends ConsumerStatefulWidget {
  final int itemId;
  final ItemType? type;
  const ItemDetailsModal({super.key, required this.itemId, this.type});

  @override
  ConsumerState<ItemDetailsModal> createState() => _ItemDetailsModalState();
}

class _ItemDetailsModalState extends ConsumerState<ItemDetailsModal> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollIndicator = false;

  @override
  void initState() {
    super.initState();
    // Check if content is scrollable after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScrollability();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    _checkScrollability();
  }

  void _checkScrollability() {
    if (!_scrollController.hasClients) return;

    final canScroll = _scrollController.position.maxScrollExtent > 0;
    final isAtBottom =
        _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10;

    setState(() {
      _showScrollIndicator = canScroll && !isAtBottom;
    });
  }

  List<Widget> _buildStackChildren(Widget content) {
    final children = <Widget>[content];
    if (_showScrollIndicator) {
      children.add(
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.0),
                    Colors.white.withOpacity(0.7),
                    Colors.white,
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.primaryBlue.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scroll for more',
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.primaryBlue.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return children;
  }

  @override
  Widget build(BuildContext context) {
    final itemAsync = widget.type != null
        ? ref.watch(
            itemDetailsWithTypeProvider((
              id: widget.itemId,
              type: widget.type!,
            )),
          )
        : ref.watch(itemDetailsProvider(widget.itemId));

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
              child: Builder(
                builder: (context) {
                  final content = Padding(
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      controller: _scrollController,
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
                          final createdAt = DateTime.parse(item.createdAt);
                          final fullDateTimeFormat = DateFormat(
                            'MMM dd, yyyy • hh:mm a',
                          );

                          final lfLabel = item.type == ItemType.found
                              ? 'Date Found'
                              : 'Date Lost';

                          // Check if user has an active claim for this item
                          final hasActiveClaimAsync =
                              item.type == ItemType.found
                              ? ref.watch(userHasActiveClaimProvider(item.id))
                              : null;

                          // Allow claims for FOUND_UNCLAIMED and CLAIM_PENDING items
                          // (multiple users can claim the same item until it's approved)
                          final bool itemAllowsClaims =
                              item.type == ItemType.found &&
                              (item.status == ItemStatus.foundUnclaimed ||
                                  item.status == ItemStatus.claimPending);

                          // Check if user has active (pending) claim (only for found items)
                          // This check runs in real-time while the system is running
                          // Returns true ONLY if claim status is 'pending'
                          // If claim is rejected/withdrawn, returns false (allows resubmission)
                          // If no claim exists, returns false (allows submission)
                          final bool userHasActiveClaim =
                              hasActiveClaimAsync != null
                              ? hasActiveClaimAsync.when(
                                  data: (hasClaim) => hasClaim,
                                  loading: () =>
                                      false, // Don't disable while loading - allow submission
                                  error: (_, __) =>
                                      false, // Don't disable on error - allow submission
                                )
                              : false;

                          // User can submit if:
                          // 1. Item allows claims (foundUnclaimed or claimPending status)
                          // 2. User doesn't have an active (pending) claim
                          //    (rejected/withdrawn claims allow resubmission)
                          final bool canSubmitClaim =
                              itemAllowsClaims && !userHasActiveClaim;

                          final String? claimDisabledReason = canSubmitClaim
                              ? null
                              : (userHasActiveClaim
                                    ? 'You already have a pending claim for this item. Please wait for admin review.'
                                    : _claimDisabledReason(item.status));

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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      item.type ==
                                                          ItemType.found
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
                                                        item.type ==
                                                            ItemType.found
                                                        ? AppTheme.successGreen
                                                        : AppTheme
                                                              .warningOrange,
                                                  ),
                                                ),
                                              ),
                                              // Status Badge
                                              StatusChip(
                                                status: item.status,
                                                itemType: item.type,
                                                fontSize: 11,
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
                                          loading: () =>
                                              const SizedBox.shrink(),
                                          error: (_, __) =>
                                              const SizedBox.shrink(),
                                          data: (me) {
                                            final isPoster =
                                                (item.ownerId == me.id) ||
                                                (item.finderId == me.id) ||
                                                (item.posterId == me.id);
                                            if (!isPoster) {
                                              return const SizedBox.shrink();
                                            }
                                            // Check if item can be edited/deleted based on status
                                            final canEditDelete = canModifyItem(
                                              item.status,
                                              item.type,
                                            );

                                            return PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == 'edit') {
                                                  if (!canEditDelete) {
                                                    ItemDialogs.showCannotEditDialog(
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
                                                              status:
                                                                  item.status,
                                                              type: item.type,
                                                              location:
                                                                  item.location,
                                                              lostFoundDate:
                                                                  item.date,
                                                              createdAt: item
                                                                  .createdAt,
                                                              updatedAt: item
                                                                  .updatedAt,
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
                                                } else if (value == 'delete') {
                                                  if (!canEditDelete) {
                                                    ItemDialogs.showCannotDeleteDialog(
                                                      context,
                                                      item.status,
                                                    );
                                                    return;
                                                  }
                                                  final confirmed =
                                                      await ItemDialogs.showDeleteConfirmationDialog(
                                                        context,
                                                        title: item.title,
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
                                                          SnackbarUtils.showItemDeleted(
                                                            context,
                                                          );
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        }
                                                      } else {
                                                        if (context.mounted) {
                                                          SnackbarUtils.showError(
                                                            context,
                                                            err,
                                                          );
                                                        }
                                                      }
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        SnackbarUtils.showError(
                                                          context,
                                                          'Failed to delete item',
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
                                                                color:
                                                                    canEditDelete
                                                                    ? AppTheme
                                                                          .darkText
                                                                    : AppTheme
                                                                          .textGray,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            if (!canEditDelete)
                                                              Text(
                                                                editDisabledReason(
                                                                  item.status,
                                                                  item.type,
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
                                                                color:
                                                                    canEditDelete
                                                                    ? AppTheme
                                                                          .errorRed
                                                                    : AppTheme
                                                                          .textGray,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            if (!canEditDelete)
                                                              Text(
                                                                deleteDisabledReason(
                                                                  item.status,
                                                                  item.type,
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
                                    color: AppTheme.primaryBlue.withOpacity(
                                      0.1,
                                    ),
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
                                      value: fullDateTimeFormat.format(
                                        createdAt,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Tip banner: show if no matches or top score < 0.60 (owner-only)
                              Builder(
                                builder: (context) {
                                  final meAsync = ref.watch(
                                    profileInfoProvider,
                                  );
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
                                      if (!isOwner)
                                        return const SizedBox.shrink();

                                      final matchesAsync = ref.watch(
                                        matchesItemsProvider(item.id),
                                      );
                                      return matchesAsync.when(
                                        loading: () => const SizedBox.shrink(),
                                        error: (_, __) =>
                                            const SizedBox.shrink(),
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
                                              borderRadius:
                                                  BorderRadius.circular(
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
                                                  Icons
                                                      .tips_and_updates_outlined,
                                                  color: AppTheme.warningOrange,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        'Improve Your Match',
                                                        style: AppTheme
                                                            .bodyMedium
                                                            .copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: AppTheme
                                                                  .darkText,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'No strong matches yet. Add color/brand or unique marks to improve results.',
                                                        style: AppTheme
                                                            .bodySmall
                                                            .copyWith(
                                                              color: AppTheme
                                                                  .darkText
                                                                  .withOpacity(
                                                                    0.8,
                                                                  ),
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
                                                        builder: (_) => EditItemScreen(
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                                  final meAsync = ref.watch(
                                    profileInfoProvider,
                                  );
                                  return meAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (me) {
                                      final canShow =
                                          (item.type == ItemType.lost &&
                                              item.ownerId == me.id) ||
                                          (item.type == ItemType.found &&
                                              item.finderId == me.id);
                                      if (!canShow)
                                        return const SizedBox.shrink();

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
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
                                                style: AppTheme.heading4
                                                    .copyWith(fontSize: 17),
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
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                    );
                                                  }
                                                  final best = matches.reduce(
                                                    (a, b) => a.score >= b.score
                                                        ? a
                                                        : b,
                                                  );
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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
                                                        alignment: Alignment
                                                            .centerLeft,
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
                                                                    itemId:
                                                                        item.id,
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
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.1,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _handleNotMineClick(
                                            context,
                                            ref,
                                            item,
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
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusMedium,
                                                  ),
                                            ),
                                          ),
                                          child: const Text(
                                            'Not mine',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton(
                                          onPressed: canSubmitClaim
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ClaimItemPage(
                                                            itemId: item.id,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.primaryBlue,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusMedium,
                                                  ),
                                            ),
                                            elevation: 2,
                                            disabledBackgroundColor:
                                                Colors.grey[300],
                                            disabledForegroundColor:
                                                AppTheme.textGray,
                                          ),
                                          child: const Text(
                                            'This is mine',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!canSubmitClaim &&
                                    claimDisabledReason != null)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: 12,
                                      left: 4,
                                      right: 4,
                                    ),
                                    child: Text(
                                      claimDisabledReason,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textGray,
                                      ),
                                    ),
                                  ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                  );
                  // Trigger scrollability check after content is built
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _checkScrollability();
                  });
                  return Stack(children: _buildStackChildren(content));
                },
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

  String? _claimDisabledReason(ItemStatus status) {
    switch (status) {
      case ItemStatus.foundUnclaimed:
      case ItemStatus.claimPending:
        return null; // Both statuses allow claims
      case ItemStatus.claimApproved:
        return 'This item has been approved for collection and is no longer available for claims.';
      case ItemStatus.collected:
        return 'This item has already been collected from the admin office.';
      case ItemStatus.resolved:
        return 'This found item has been matched to a lost report.';
      case ItemStatus.lostReported:
        return 'Claims are only available for found items.';
    }
  }

  /// Handle "Not Mine" button click - removes item from recommendations and sends AI feedback
  Future<void> _handleNotMineClick(
    BuildContext context,
    WidgetRef ref,
    Item foundItem,
  ) async {
    // Close the dialog first
    Navigator.pop(context);

    // ✅ IMMEDIATE REMOVAL: Add item to dismissed list (client-side filtering)
    // This instantly removes the item from recommendations without waiting for backend
    ref.read(dismissedItemsProvider.notifier).state = {
      ...ref.read(dismissedItemsProvider),
      foundItem.id,
    };

    // Show feedback message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Got it. We\'ll refine your matches.'),
        backgroundColor: AppTheme.textGray,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );

    // Send AI feedback to improve matching system (backend learning)
    // This helps the AI learn from user feedback for future recommendations
    try {
      final itemService = ref.read(itemServiceProvider);

      // Try to find user's lost items that might match this found item
      // This helps identify which lost item was incorrectly matched
      final postedItemsAsync = ref.read(postedItemsProvider);
      final postedItems = postedItemsAsync.asData?.value ?? <PostedItem>[];

      // Get user's lost items (only open/lostReported status)
      final userLostItems = postedItems
          .where(
            (postedItem) =>
                postedItem.type == ItemType.lost &&
                postedItem.status == ItemStatus.lostReported,
          )
          .toList();

      // Send negative feedback for each potential match
      // This tells the AI system that these items don't match
      for (final lostItem in userLostItems) {
        await itemService.postAiFeedback(
          itemId: foundItem.id,
          matchedItemId: lostItem.id,
          action: 'negative', // Negative feedback - item doesn't match
          source: 'detail', // Source: item details screen
        );
      }

      // Also try to get matches from recommendations to send feedback
      // This covers cases where the item was shown in recommendations
      try {
        final recommendedAsync = ref.read(recommendedItemsProvider);
        final recommendedItems =
            recommendedAsync.asData?.value ?? <MatchScoreItem>[];

        // Find if this found item was in recommendations with a lost item match
        for (final match in recommendedItems) {
          if (match.item?.id == foundItem.id && match.lostItem != null) {
            // Send negative feedback for this specific match
            await itemService.postAiFeedback(
              itemId: foundItem.id,
              matchedItemId: match.lostItem!.id,
              action: 'negative',
              source: 'detail',
            );
          }
        }
      } catch (e) {
        // If we can't get recommendations, continue anyway
        print('Could not fetch recommendations for AI feedback: $e');
      }
    } catch (e) {
      // AI feedback is best-effort - don't show error to user
      // The system will continue to work even if feedback fails
      print('AI feedback error (non-critical): $e');
    }
  }
}
