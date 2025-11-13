import 'package:navistfind/features/auth/application/auth_provider.dart';
import 'package:navistfind/features/lost_found/item/presentation/item_details_screen.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/profile/domain/models/claim_request.dart';
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
import 'package:navistfind/widgets/claim_request_card.dart';
import 'package:intl/intl.dart';
import 'package:navistfind/features/profile/presentation/edit_claim_request_page.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showAllClaimRequests = false;
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

  Future<bool> _cancelClaimRequest(
    BuildContext context,
    WidgetRef ref,
    ClaimRequest claim,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel claim request?'),
        content: const Text(
          'This will remove your claim request for this item. You can submit another request later if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    final notifier = ref.read(claimRequestsProvider.notifier);
    final error = await notifier.cancelClaim(claim.id);

    if (!mounted) {
      return false;
    }

    if (error == null) {
      SnackbarUtils.showSuccess(context, 'Claim request cancelled');
      return true;
    } else {
      SnackbarUtils.showError(context, error);
      return false;
    }
  }

  Future<bool> _deleteClaimRequest(
    BuildContext context,
    WidgetRef ref,
    ClaimRequest claim,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete claim record?'),
        content: const Text(
          'This will permanently remove this claim request from your history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Record'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    final notifier = ref.read(claimRequestsProvider.notifier);
    final error = await notifier.deleteClaim(claim.id);

    if (!mounted) {
      return false;
    }

    if (error == null) {
      SnackbarUtils.showSuccess(context, 'Claim request removed');
      return true;
    } else {
      SnackbarUtils.showError(context, error);
      return false;
    }
  }

  Future<void> _openEditClaimRequest(
    BuildContext context,
    WidgetRef ref,
    ClaimRequest claim,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditClaimRequestPage(claim: claim)),
    );

    if (updated == true && mounted) {
      SnackbarUtils.showSuccess(context, 'Claim request updated');
    }
  }

  Future<void> _showClaimDetailsModal(
    BuildContext context,
    WidgetRef ref,
    ClaimRequest claim,
  ) async {
    final parentContext = context;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      builder: (sheetContext) {
        bool isCancelling = false;
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (builderContext, setState) {
            final foundItem = claim.foundItem;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(builderContext).viewInsets.bottom + 20,
                  top: 20,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                            ),
                            child: const Icon(
                              Icons.assignment_outlined,
                              color: AppTheme.primaryBlue,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  foundItem?.title ?? 'Claim Request',
                                  style: AppTheme.heading3.copyWith(
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (foundItem?.location != null &&
                                    foundItem!.location!.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.place_outlined,
                                        size: 16,
                                        color: AppTheme.textGray,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          foundItem.location!,
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.textGray,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          _StatusChip(status: claim.status),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (claim.message != null &&
                          claim.message!.isNotEmpty) ...[
                        Text('Claim Message', style: AppTheme.heading4),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.lightPanel,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusMedium,
                            ),
                          ),
                          child: Text(
                            claim.message!,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.darkText,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildDetailRow(
                        icon: Icons.access_time,
                        label: 'Submitted',
                        value: claim.submittedAt != null
                            ? DateFormat(
                                'MMM d, y – h:mm a',
                              ).format(claim.submittedAt!.toLocal())
                            : 'Unknown',
                      ),
                      if (claim.approvedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildDetailRow(
                            icon: Icons.verified_outlined,
                            label: 'Approved',
                            value: DateFormat(
                              'MMM d, y – h:mm a',
                            ).format(claim.approvedAt!.toLocal()),
                          ),
                        ),
                      if (claim.rejectedAt != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildDetailRow(
                            icon: Icons.event_busy_outlined,
                            label: 'Decision',
                            value: DateFormat(
                              'MMM d, y – h:mm a',
                            ).format(claim.rejectedAt!.toLocal()),
                          ),
                        ),
                      if (foundItem?.collectionDeadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _buildDetailRow(
                            icon: Icons.calendar_month_outlined,
                            label: 'Collect By',
                            value: DateFormat(
                              'MMM d, y',
                            ).format(foundItem!.collectionDeadline!.toLocal()),
                          ),
                        ),
                      if (claim.rejectionReason != null &&
                          claim.rejectionReason!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.errorRed.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusMedium,
                              ),
                              border: Border.all(
                                color: AppTheme.errorRed.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline,
                                  color: AppTheme.errorRed,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    claim.rejectionReason!,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: AppTheme.errorRed,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (claim.status == ClaimRequestStatus.pending)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: isCancelling
                                      ? null
                                      : () {
                                          Navigator.of(sheetContext).pop();
                                          Future.microtask(() {
                                            if (mounted) {
                                              _openEditClaimRequest(
                                                parentContext,
                                                ref,
                                                claim,
                                              );
                                            }
                                          });
                                        },
                                  style: AppTheme.getPrimaryButtonStyle(),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text(
                                    'Edit Claim Request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: isCancelling
                                      ? null
                                      : () async {
                                          setState(() => isCancelling = true);
                                          final success =
                                              await _cancelClaimRequest(
                                                sheetContext,
                                                ref,
                                                claim,
                                              );
                                          if (success && sheetContext.mounted) {
                                            Navigator.of(sheetContext).pop();
                                          } else {
                                            setState(
                                              () => isCancelling = false,
                                            );
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppTheme.errorRed,
                                    side: const BorderSide(
                                      color: AppTheme.errorRed,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusMedium,
                                      ),
                                    ),
                                  ),
                                  icon: isCancelling
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.errorRed,
                                          ),
                                        )
                                      : const Icon(Icons.close_outlined),
                                  label: const Text(
                                    'Cancel Request',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (claim.status == ClaimRequestStatus.approved ||
                          claim.status == ClaimRequestStatus.rejected)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: OutlinedButton.icon(
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    setState(() => isDeleting = true);
                                    final success = await _deleteClaimRequest(
                                      sheetContext,
                                      ref,
                                      claim,
                                    );
                                    if (success && sheetContext.mounted) {
                                      Navigator.of(sheetContext).pop();
                                    } else {
                                      setState(() => isDeleting = false);
                                    }
                                  },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorRed,
                              side: const BorderSide(color: AppTheme.errorRed),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                              ),
                            ),
                            icon: isDeleting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.errorRed,
                                    ),
                                  )
                                : const Icon(Icons.delete_outline),
                            label: const Text(
                              'Delete Claim',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildClaimRequestsEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.assignment_turned_in_outlined,
      title: 'No Claim Requests Yet',
      subtitle: 'Claims you submit for found items will appear in this list.',
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXL),
    );
  }

  Widget _buildClaimRequestsErrorState(dynamic error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.errorRed.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppTheme.errorRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to load claim requests',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error?.toString() ?? 'Please try again shortly.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.textGray),
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
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

              final claimRequestsAsync = ref.watch(claimRequestsProvider);
              final bool canToggleClaims = claimRequestsAsync.maybeWhen(
                data: (claims) => claims.length > 4,
                orElse: () => false,
              );

              final slivers = <Widget>[
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: const SectionHeader(
                      title: 'Your Lost Items',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                ),
              ];

              if (sortedItems.isEmpty) {
                slivers.add(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildEmptyState(context, ''),
                    ),
                  ),
                );
              } else {
                slivers.add(
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: SizedBox(
                        height: 240,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemExtent: 202,
                          itemCount: sortedItems.length,
                          itemBuilder: (context, idx) {
                            final rightPad = idx == sortedItems.length - 1
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
                );
              }

              slivers.add(
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Row(
                      children: [
                        const Expanded(
                          child: SectionHeader(
                            title: 'Claim Requests',
                            icon: Icons.assignment_outlined,
                          ),
                        ),
                        if (canToggleClaims)
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAllClaimRequests = !_showAllClaimRequests;
                              });
                            },
                            icon: Icon(
                              _showAllClaimRequests
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: AppTheme.primaryBlue,
                            ),
                            label: Text(
                              _showAllClaimRequests ? 'Hide extra' : 'Show all',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlue,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );

              slivers.add(
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: claimRequestsAsync.when(
                    loading: () => const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    error: (error, stack) => SliverToBoxAdapter(
                      child: _buildClaimRequestsErrorState(error),
                    ),
                    data: (claims) {
                      if (claims.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _buildClaimRequestsEmptyState(context),
                        );
                      }

                      final bool limitClaims =
                          !_showAllClaimRequests && claims.length > 4;
                      final List<ClaimRequest> visibleClaims = limitClaims
                          ? claims.take(4).toList()
                          : claims;

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final claim = visibleClaims[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == visibleClaims.length - 1
                                  ? 0
                                  : 16,
                            ),
                            child: ClaimRequestCard(
                              claim: claim,
                              onTap: () =>
                                  _showClaimDetailsModal(context, ref, claim),
                            ),
                          );
                        }, childCount: visibleClaims.length),
                      );
                    },
                  ),
                ),
              );

              return CustomScrollView(slivers: slivers);
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

  Widget _StatusChip({required ClaimRequestStatus status}) {
    final color = status == ClaimRequestStatus.pending
        ? AppTheme.warningOrange
        : status == ClaimRequestStatus.approved
        ? AppTheme.successGreen
        : AppTheme.errorRed;
    final icon = status == ClaimRequestStatus.pending
        ? Icons.pending_outlined
        : status == ClaimRequestStatus.approved
        ? Icons.check_circle_rounded
        : Icons.event_busy_outlined;
    final label = status == ClaimRequestStatus.pending
        ? 'Pending'
        : status == ClaimRequestStatus.approved
        ? 'Approved'
        : 'Rejected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
