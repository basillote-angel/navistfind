enum ClaimStatus { pending, approved, rejected, withdrawn }

extension ClaimStatusExtension on ClaimStatus {
  static const Map<String, ClaimStatus> _values = {
    'PENDING': ClaimStatus.pending,
    'APPROVED': ClaimStatus.approved,
    'REJECTED': ClaimStatus.rejected,
    'WITHDRAWN': ClaimStatus.withdrawn,
    'CANCELLED': ClaimStatus.withdrawn,
    'CANCELED': ClaimStatus.withdrawn,
  };

  static ClaimStatus fromString(String value) {
    final normalized = value.trim().toUpperCase();
    return _values[normalized] ?? ClaimStatus.pending;
  }

  static ClaimStatus safeValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ClaimStatus.pending;
    }
    return fromString(value);
  }

  String get apiValue {
    switch (this) {
      case ClaimStatus.pending:
        return 'PENDING';
      case ClaimStatus.approved:
        return 'APPROVED';
      case ClaimStatus.rejected:
        return 'REJECTED';
      case ClaimStatus.withdrawn:
        return 'WITHDRAWN';
    }
  }

  String get displayLabel {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.withdrawn:
        return 'Withdrawn';
    }
  }

  bool get isFinal =>
      this == ClaimStatus.approved ||
      this == ClaimStatus.rejected ||
      this == ClaimStatus.withdrawn;
}



