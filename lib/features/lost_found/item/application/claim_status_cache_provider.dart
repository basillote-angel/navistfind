import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';

class ClaimStatusCacheNotifier extends StateNotifier<Map<int, ClaimStatus>> {
  ClaimStatusCacheNotifier() : super(const {});

  void setStatus(int itemId, ClaimStatus status) {
    state = {...state, itemId: status};
  }

  void clear(int itemId) {
    if (!state.containsKey(itemId)) return;
    final updated = {...state}..remove(itemId);
    state = updated;
  }

  ClaimStatus? statusFor(int itemId) => state[itemId];
}

final claimStatusCacheProvider =
    StateNotifierProvider<ClaimStatusCacheNotifier, Map<int, ClaimStatus>>((
      ref,
    ) {
      return ClaimStatusCacheNotifier();
    });



