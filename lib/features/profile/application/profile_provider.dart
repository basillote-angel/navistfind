import 'package:navistfind/features/profile/data/profile_service.dart';
import 'package:navistfind/features/profile/domain/models/posted-item.dart';
import 'package:navistfind/features/profile/domain/models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/application/claim_provider.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/item_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'posted_items_notifier.dart';

final profileServiceProvider = Provider((ref) => ProfileService());

final profileInfoProvider = FutureProvider<User>((ref) async {
  final profileInfo = ref.read(profileServiceProvider);
  return await profileInfo.fetchInfo();
});

final postedItemsProvider =
    StateNotifierProvider<PostedItemsNotifier, AsyncValue<List<PostedItem>>>(
      (ref) => PostedItemsNotifier(ref.read(profileServiceProvider)),
    );

/// Provider to fetch user's claim statistics (pending and approved claims on found items)
final userClaimStatisticsProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  try {
    final user = await ref.read(profileInfoProvider.future);
    final itemService = ref.read(itemServiceProvider);

    // Fetch all found items with claimPending and claimApproved status
    final pendingItems = await itemService.fetchItemsFiltered(
      type: ItemType.found,
    );

    // Filter to only items with claimPending or claimApproved status
    final claimItems = pendingItems
        .where(
          (item) =>
              item.status == ItemStatus.claimPending ||
              item.status == ItemStatus.claimApproved,
        )
        .toList();

    int claimsPending = 0;
    int awaitingPickup = 0;

    // Check each item to see if user has a claim on it
    final claimService = ref.read(claimServiceProvider);
    for (final item in claimItems) {
      try {
        final claimDetail = await claimService.fetchClaimDetail(item.id);
        final isUserClaim = _isClaimBelongsToUser(
          claimDetail,
          user.email,
          user.name,
        );

        if (isUserClaim) {
          if (item.status == ItemStatus.claimPending) {
            claimsPending++;
          } else if (item.status == ItemStatus.claimApproved) {
            awaitingPickup++;
          }
        }
      } catch (_) {
        // If we can't fetch claim detail, skip this item
        continue;
      }
    }

    return {'claimsPending': claimsPending, 'awaitingPickup': awaitingPickup};
  } catch (_) {
    // Return zeros on error
    return {'claimsPending': 0, 'awaitingPickup': 0};
  }
});

/// Helper function to check if a claim belongs to the current user
bool _isClaimBelongsToUser(
  ClaimDetail claim,
  String userEmail,
  String userName,
) {
  // Normalize strings for comparison
  final normalize = (String s) => s.trim().toLowerCase();
  final normalizedUserEmail = normalize(userEmail);
  final normalizedUserName = normalize(userName);

  // Check if claimant email matches user email
  if (claim.claimantContact != null) {
    final normalizedClaimantContact = normalize(claim.claimantContact!);
    if (normalizedClaimantContact == normalizedUserEmail) {
      return true;
    }
  }

  // Check if claimant name matches user name
  if (claim.claimantName != null) {
    final normalizedClaimantName = normalize(claim.claimantName!);
    if (normalizedClaimantName == normalizedUserName) {
      return true;
    }
  }

  return false;
}
