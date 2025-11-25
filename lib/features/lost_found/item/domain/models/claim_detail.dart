import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/core/constants.dart';

class ClaimDetail {
  ClaimDetail({
    required this.id,
    required this.itemId,
    required this.status,
    required this.message,
    required this.submittedAt,
    this.updatedAt,
    this.foundItemTitle,
    this.claimantName,
    this.claimantContact,
    this.adminNotes,
    this.rejectionReason,
    this.collectionInstructions,
    this.collectionLocation,
    this.collectionDeadline,
    this.canEdit = false,
    this.canCancel = false,
    this.claimImage,
    this.claimImageUrl,
  });

  final int id;
  final int itemId;
  final ClaimStatus status;
  final String message;
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final String? foundItemTitle;
  final String? claimantName;
  final String? claimantContact;
  final String? adminNotes;
  final String? rejectionReason;
  final String? collectionInstructions;
  final String? collectionLocation;
  final DateTime? collectionDeadline;
  final bool canEdit;
  final bool canCancel;
  final String? claimImage;
  final String? claimImageUrl;

  factory ClaimDetail.fromJson(Map<String, dynamic> json) {
    DateTime? _tryParse(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }

    final status = ClaimStatusExtension.safeValue(
      json['status']?.toString() ?? '',
    );
    final submittedAt = _tryParse(
      json['submitted_at']?.toString() ??
          json['created_at']?.toString() ??
          json['submittedAt']?.toString(),
    );
    final foundItem = json['found_item'] ?? json['foundItem'];
    String? foundItemTitle;
    if (foundItem is Map) {
      final map = Map<String, dynamic>.from(foundItem);
      foundItemTitle = (map['title'] ?? map['name'])?.toString();
    }

    return ClaimDetail(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      itemId: json['item_id'] is int
          ? json['item_id'] as int
          : int.tryParse('${json['item_id']}') ??
                json['found_item_id'] as int? ??
                int.tryParse('${json['found_item_id']}') ??
                0,
      status: status,
      message: (json['message'] ?? json['claim_message'] ?? '').toString(),
      submittedAt: submittedAt ?? DateTime.now(),
      updatedAt: _tryParse(
        json['updated_at']?.toString() ?? json['updatedAt']?.toString(),
      ),
      foundItemTitle: foundItemTitle,
      claimantName:
          (json['claimant_name'] ??
                  json['claimant']?['name'] ??
                  json['claimantName'])
              ?.toString(),
      claimantContact:
          (json['claimant_contact'] ??
                  json['claimant_contact_info'] ??
                  json['claimant']?['contactInfo'] ??
                  json['claimant']?['contact'] ??
                  json['contact_info'] ??
                  json['contactInfo'])
              ?.toString(),
      adminNotes: (json['admin_notes'] ?? json['adminNotes'])?.toString(),
      rejectionReason: (json['rejection_reason'] ?? json['rejectionReason'])
          ?.toString(),
      collectionInstructions:
          (json['collection_instructions'] ??
                  json['collectionInstructions'] ??
                  json['pickup_instructions'] ??
                  json['pickupInstructions'])
              ?.toString(),
      collectionLocation:
          (json['collection_location'] ??
                  json['collectionLocation'] ??
                  json['pickup_location'] ??
                  json['pickupLocation'])
              ?.toString(),
      collectionDeadline: _tryParse(
        json['collection_deadline']?.toString() ??
            json['collectionDeadline']?.toString(),
      ),
      canEdit:
          json['can_edit'] == true ||
          json['canEdit'] == true ||
          status == ClaimStatus.pending,
      canCancel:
          json['can_cancel'] == true ||
          json['canCancel'] == true ||
          status == ClaimStatus.pending,
      claimImage: (json['claim_image'] ?? json['claimImage'])?.toString(),
      claimImageUrl:
          (json['claim_image_url'] ?? json['claimImageUrl'])?.toString() ??
          ((json['claim_image'] ?? json['claimImage']) != null
              ? '${Constants.backendBaseUrl}/storage/${json['claim_image'] ?? json['claimImage']}'
              : null),
    );
  }

  ClaimDetail copyWith({
    ClaimStatus? status,
    String? message,
    String? adminNotes,
    String? rejectionReason,
    String? collectionInstructions,
    String? collectionLocation,
    DateTime? collectionDeadline,
    bool? canEdit,
    bool? canCancel,
    String? foundItemTitle,
    String? claimantName,
    String? claimantContact,
  }) {
    return ClaimDetail(
      id: id,
      itemId: itemId,
      status: status ?? this.status,
      message: message ?? this.message,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      foundItemTitle: foundItemTitle ?? this.foundItemTitle,
      claimantName: claimantName ?? this.claimantName,
      claimantContact: claimantContact ?? this.claimantContact,
      adminNotes: adminNotes ?? this.adminNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      collectionInstructions:
          collectionInstructions ?? this.collectionInstructions,
      collectionLocation: collectionLocation ?? this.collectionLocation,
      collectionDeadline: collectionDeadline ?? this.collectionDeadline,
      canEdit: canEdit ?? this.canEdit,
      canCancel: canCancel ?? this.canCancel,
    );
  }
}
