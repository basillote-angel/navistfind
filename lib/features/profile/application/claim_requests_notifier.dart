import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/profile/data/profile_service.dart';
import 'package:navistfind/features/profile/domain/models/claim_request.dart';

class ClaimRequestsNotifier
    extends StateNotifier<AsyncValue<List<ClaimRequest>>> {
  ClaimRequestsNotifier(this._service) : super(const AsyncLoading()) {
    loadClaims();
  }

  final ProfileService _service;

  List<ClaimRequest> _filterVisible(List<ClaimRequest> claims) {
    return claims
        .where((claim) => claim.status != ClaimRequestStatus.withdrawn)
        .toList();
  }

  Future<void> loadClaims() async {
    try {
      final claims = await _service.fetchClaimRequests();
      state = AsyncData(_filterVisible(claims));
    } catch (error) {
      // ignore: avoid_print
      print('claimRequests load error: $error');
      state = const AsyncData(<ClaimRequest>[]);
    }
  }

  Future<String?> cancelClaim(int claimId) async {
    final previousClaims = state.value ?? <ClaimRequest>[];
    final existing = previousClaims.where((item) => item.id == claimId);

    if (existing.isEmpty) {
      return 'Claim not found';
    }

    final claim = existing.first;
    if (claim.status != ClaimRequestStatus.pending) {
      return 'Only pending claims can be cancelled';
    }

    final optimisticClaims = previousClaims
        .where((item) => item.id != claimId)
        .toList();
    state = AsyncData(optimisticClaims);

    try {
      await _service.cancelClaim(claimId);
      final refreshed = await _service.fetchClaimRequests();
      state = AsyncData(_filterVisible(refreshed));
      return null;
    } catch (error) {
      state = AsyncData(previousClaims);
      return 'Failed to cancel claim';
    }
  }

  // Legacy helpers for existing UI call sites.
  Future<String?> deleteClaim(int claimId) => cancelClaim(claimId);

  Future<String?> updateClaim({
    required int claimId,
    required String message,
    String? contactName,
    String? contactInfo,
  }) async {
    // Editing claims is not yet supported by the backend. Return an error message
    // so callers can surface feedback to the user without crashing.
    return 'Updating claim requests is not supported yet.';
  }
}
