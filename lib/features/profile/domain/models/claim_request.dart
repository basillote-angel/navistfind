enum ClaimRequestStatus { pending, approved, rejected, withdrawn }

extension ClaimRequestStatusExtension on ClaimRequestStatus {
  static ClaimRequestStatus fromString(String value) {
    switch (value) {
      case 'approved':
        return ClaimRequestStatus.approved;
      case 'rejected':
        return ClaimRequestStatus.rejected;
      case 'withdrawn':
        return ClaimRequestStatus.withdrawn;
      case 'pending':
      default:
        return ClaimRequestStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case ClaimRequestStatus.pending:
        return 'Pending Review';
      case ClaimRequestStatus.approved:
        return 'Approved';
      case ClaimRequestStatus.rejected:
        return 'Rejected';
      case ClaimRequestStatus.withdrawn:
        return 'Cancelled';
    }
  }
}

class ClaimRequestItem {
  const ClaimRequestItem({
    required this.id,
    required this.title,
    required this.status,
    required this.location,
    required this.categoryName,
    required this.imageUrl,
    required this.collectionDeadline,
  });

  final int id;
  final String title;
  final String? status;
  final String? location;
  final String? categoryName;
  final String? imageUrl;
  final DateTime? collectionDeadline;

  factory ClaimRequestItem.fromJson(Map<String, dynamic> json) {
    return ClaimRequestItem(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      status: json['status']?.toString(),
      location: json['location']?.toString(),
      categoryName: json['categoryName']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      collectionDeadline: _parseDateTime(json['collectionDeadline']),
    );
  }
}

class ClaimRequest {
  const ClaimRequest({
    required this.id,
    required this.foundItemId,
    required this.status,
    required this.message,
    required this.submittedAt,
    required this.updatedAt,
    required this.approvedAt,
    required this.rejectedAt,
    required this.rejectionReason,
    required this.isPrimaryClaim,
    required this.foundItem,
    required this.claimantContactName,
    required this.claimantContactInfo,
  });

  final int id;
  final int foundItemId;
  final ClaimRequestStatus status;
  final String? message;
  final DateTime? submittedAt;
  final DateTime? updatedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final bool isPrimaryClaim;
  final ClaimRequestItem? foundItem;
  final String? claimantContactName;
  final String? claimantContactInfo;

  factory ClaimRequest.fromJson(Map<String, dynamic> json) {
    return ClaimRequest(
      id: json['id'] as int,
      foundItemId: json['foundItemId'] as int,
      status: ClaimRequestStatusExtension.fromString(
        json['status']?.toString() ?? 'pending',
      ),
      message: json['message']?.toString(),
      submittedAt: _parseDateTime(json['submittedAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      approvedAt: _parseDateTime(json['approvedAt']),
      rejectedAt: _parseDateTime(json['rejectedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      isPrimaryClaim: json['isPrimaryClaim'] == true,
      foundItem: json['foundItem'] is Map<String, dynamic>
          ? ClaimRequestItem.fromJson(json['foundItem'] as Map<String, dynamic>)
          : json['foundItem'] is Map
          ? ClaimRequestItem.fromJson(
              Map<String, dynamic>.from(json['foundItem'] as Map),
            )
          : null,
      claimantContactName:
          (json['claimantContactName'] ??
                  json['claimant_contact_name'] ??
                  json['contactName'] ??
                  json['contact_name'])
              ?.toString(),
      claimantContactInfo:
          (json['claimantContactInfo'] ??
                  json['claimant_contact_info'] ??
                  json['contactInfo'] ??
                  json['contact_info'])
              ?.toString(),
    );
  }

  ClaimRequest copyWith({
    ClaimRequestStatus? status,
    String? message,
    String? claimantContactName,
    String? claimantContactInfo,
  }) {
    return ClaimRequest(
      id: id,
      foundItemId: foundItemId,
      status: status ?? this.status,
      message: message ?? this.message,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      approvedAt: approvedAt,
      rejectedAt: rejectedAt,
      rejectionReason: rejectionReason,
      isPrimaryClaim: isPrimaryClaim,
      foundItem: foundItem,
      claimantContactName: claimantContactName ?? this.claimantContactName,
      claimantContactInfo: claimantContactInfo ?? this.claimantContactInfo,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String && value.isEmpty) {
    return null;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}
