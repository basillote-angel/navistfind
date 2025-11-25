import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:navistfind/features/lost_found/item/application/item_provider.dart';
import 'package:navistfind/features/lost_found/item/data/claim_service.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/features/lost_found/post-item/domain/enums/item_type.dart';
import 'package:navistfind/features/profile/application/profile_provider.dart';

final claimServiceProvider = Provider<ClaimService>((ref) {
  return ClaimService();
});

final claimDetailProvider = FutureProvider.autoDispose.family<ClaimDetail, int>(
  (ref, itemId) async {
    final service = ref.read(claimServiceProvider);
    final detail = await service.fetchClaimDetail(itemId);
    return detail;
  },
);

/// Provider to check if the current user has an active (pending) claim for an item
///
/// Returns:
/// - `true` if user has a claim with status `pending` (button should be disabled)
/// - `false` if:
///   - User has no claim for this item
///   - User has a rejected/withdrawn claim (allows resubmission)
///   - User has an approved claim (item already claimed)
///   - Any error occurs (allows submission to let backend handle validation)
///
/// This check runs in real-time while the system is running, allowing users
/// to resubmit claims if their previous claim was rejected or withdrawn.
final userHasActiveClaimProvider = FutureProvider.autoDispose.family<bool, int>((
  ref,
  itemId,
) async {
  try {
    // Get current user profile
    final userAsync = await ref.read(profileInfoProvider.future);

    // Try to fetch claim detail for the item
    try {
      final claimDetail = await ref.read(claimDetailProvider(itemId).future);

      // Check if claim exists and belongs to current user
      final isUserClaim = _isClaimBelongsToUser(
        claimDetail,
        userAsync.email,
        userAsync.name,
      );

      // Only block if it's the user's claim AND status is pending
      // If status is rejected/withdrawn, allow resubmission (return false)
      // If status is approved, the item status will prevent claims anyway
      if (isUserClaim && claimDetail.status == ClaimStatus.pending) {
        return true; // User has active pending claim - disable button
      }

      // User's claim is rejected/withdrawn/approved OR not user's claim
      // Allow submission (backend will handle validation)
      return false;
    } on DioException catch (e) {
      // If 404 or no claim found, user doesn't have a claim - allow submission
      if (e.response?.statusCode == 404) {
        return false;
      }
      // For other errors, return false (assume no active claim) - allow submission
      // Backend will handle validation if there's actually a pending claim
      return false;
    } catch (_) {
      // Any other error, assume no active claim - allow submission
      // Backend will handle validation
      return false;
    }
  } catch (_) {
    // If we can't get user profile or claim, assume no active claim
    // Allow submission - backend will handle validation
    return false;
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

class ClaimRequestsNotifier extends StateNotifier<AsyncValue<void>> {
  ClaimRequestsNotifier(this._claimService, this._ref)
    : super(const AsyncValue.data(null));

  final ClaimService _claimService;
  final Ref _ref;

  Future<String?> updateClaim({
    required int itemId,
    required String message,
    required String contactName,
    required String contactInfo,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _claimService.updateClaim(
        itemId: itemId,
        message: message,
        contactName: contactName,
        contactInfo: contactInfo,
      );
      _invalidateClaimCaches(itemId);
      state = const AsyncValue.data(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return _mapError(error);
    }
  }

  Future<String?> cancelClaim({required int itemId, int? claimId}) async {
    state = const AsyncValue.loading();
    try {
      await _claimService.cancelClaim(itemId: itemId, claimId: claimId);
      _invalidateClaimCaches(itemId);
      state = const AsyncValue.data(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return _mapError(error);
    }
  }

  void _invalidateClaimCaches(int itemId) {
    _ref.invalidate(claimDetailProvider(itemId));
    _ref.invalidate(itemDetailsProvider(itemId));
    _ref.invalidate(
      itemDetailsWithTypeProvider((id: itemId, type: _resolveItemType(itemId))),
    );
    _ref.invalidate(itemListProvider);
  }

  ItemType _resolveItemType(int itemId) {
    final cached = _ref
        .read(itemDetailsProvider(itemId))
        .maybeWhen(data: (data) => data.type, orElse: () => null);
    return cached ?? ItemType.found;
  }

  String _mapError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status == 404) {
        return 'We could not find an active claim for this item.';
      }
      if (status == 409) {
        return 'You already have a pending claim. Please wait for the admin review.';
      }
      final message = error.response?.data is Map
          ? (error.response?.data['message'] as String?)
          : error.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return 'Something went wrong. Please try again later.';
  }
}

final claimRequestsProvider =
    StateNotifierProvider<ClaimRequestsNotifier, AsyncValue<void>>((ref) {
      return ClaimRequestsNotifier(ref.read(claimServiceProvider), ref);
    });
