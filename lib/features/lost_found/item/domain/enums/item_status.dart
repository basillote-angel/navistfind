enum ItemStatus {
  lostReported,
  resolved,
  foundUnclaimed,
  claimPending,
  claimApproved,
  collected,
}

extension ItemStatusExtension on ItemStatus {
  static const Map<String, ItemStatus> _canonicalValues = {
    'LOST_REPORTED': ItemStatus.lostReported,
    'RESOLVED': ItemStatus.resolved,
    'FOUND_UNCLAIMED': ItemStatus.foundUnclaimed,
    'CLAIM_PENDING': ItemStatus.claimPending,
    'CLAIM_APPROVED': ItemStatus.claimApproved,
    'COLLECTED': ItemStatus.collected,
  };

  static const Map<String, ItemStatus> _legacyValues = {
    'OPEN': ItemStatus.lostReported,
    'MATCHED': ItemStatus.resolved,
    'UNCLAIMED': ItemStatus.foundUnclaimed,
    'PENDING': ItemStatus.claimPending,
    'RETURNED': ItemStatus.claimApproved,
    'CLAIMED': ItemStatus.claimApproved,
    'APPROVED': ItemStatus.claimApproved,
    'CLOSED': ItemStatus.collected,
  };

  static ItemStatus fromString(String status) {
    final normalized = status.trim();
    if (normalized.isEmpty) return ItemStatus.lostReported;

    final upper = normalized.toUpperCase();
    return _canonicalValues[upper] ??
        _legacyValues[upper] ??
        (throw Exception('Unknown ItemStatus: $status'));
  }

  static ItemStatus safeValue(
    String? status, {
    ItemStatus fallback = ItemStatus.lostReported,
  }) {
    if (status == null || status.trim().isEmpty) return fallback;
    try {
      return fromString(status);
    } catch (_) {
      return fallback;
    }
  }

  String get apiValue {
    switch (this) {
      case ItemStatus.lostReported:
        return 'LOST_REPORTED';
      case ItemStatus.resolved:
        return 'RESOLVED';
      case ItemStatus.foundUnclaimed:
        return 'FOUND_UNCLAIMED';
      case ItemStatus.claimPending:
        return 'CLAIM_PENDING';
      case ItemStatus.claimApproved:
        return 'CLAIM_APPROVED';
      case ItemStatus.collected:
        return 'COLLECTED';
    }
  }

  String get displayLabel {
    switch (this) {
      case ItemStatus.lostReported:
        return 'Lost Reported';
      case ItemStatus.resolved:
        return 'Resolved';
      case ItemStatus.foundUnclaimed:
        return 'Found Unclaimed';
      case ItemStatus.claimPending:
        return 'Claim Pending';
      case ItemStatus.claimApproved:
        return 'Claim Approved';
      case ItemStatus.collected:
        return 'Collected';
    }
  }

  bool get isLostLifecycle =>
      this == ItemStatus.lostReported || this == ItemStatus.resolved;

  bool get isFoundLifecycle =>
      this == ItemStatus.foundUnclaimed ||
      this == ItemStatus.claimPending ||
      this == ItemStatus.claimApproved ||
      this == ItemStatus.collected;

  bool get isClaimLifecycle =>
      this == ItemStatus.claimPending || this == ItemStatus.claimApproved;

  bool get isTerminal =>
      this == ItemStatus.resolved || this == ItemStatus.collected;
}
