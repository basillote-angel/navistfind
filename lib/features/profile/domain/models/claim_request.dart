import 'package:navistfind/features/lost_found/item/domain/enums/claim_status.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';

class ClaimRequest {
  ClaimRequest({
    required this.id,
    required this.foundItemId,
    required this.status,
    this.message,
    this.foundItemTitle,
    this.claimantContactName,
    this.claimantContactInfo,
    this.adminNotes,
    this.rejectionReason,
    this.collectionInstructions,
    this.collectionLocation,
    this.collectionDeadline,
    this.submittedAt,
    this.updatedAt,
  });

  final int id;
  final int foundItemId;
  final ClaimStatus status;
  final String? message;
  final String? foundItemTitle;
  final String? claimantContactName;
  final String? claimantContactInfo;
  final String? adminNotes;
  final String? rejectionReason;
  final String? collectionInstructions;
  final String? collectionLocation;
  final DateTime? collectionDeadline;
  final DateTime? submittedAt;
  final DateTime? updatedAt;

  factory ClaimRequest.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(String? value) {
      if (value == null || value.isEmpty) return null;
      try {
        return DateTime.parse(value).toLocal();
      } catch (_) {
        return null;
      }
    }

    return ClaimRequest(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      foundItemId: json['found_item_id'] is int
          ? json['found_item_id'] as int
          : int.tryParse('${json['found_item_id']}') ??
                json['item_id'] as int? ??
                int.tryParse('${json['item_id']}') ??
                0,
      status: ClaimStatusExtension.safeValue(json['status']?.toString() ?? ''),
      message: (json['message'] ?? json['claim_message'])?.toString(),
      foundItemTitle:
          (json['found_item']?['title'] ??
                  json['foundItem']?['title'] ??
                  json['found_item_title'] ??
                  json['foundItemTitle'])
              ?.toString(),
      claimantContactName:
          (json['claimant_contact_name'] ??
                  json['claimant_name'] ??
                  json['claimant']?['name'])
              ?.toString(),
      claimantContactInfo:
          (json['claimant_contact_info'] ??
                  json['contact_info'] ??
                  json['claimant']?['contactInfo'])
              ?.toString(),
      adminNotes: (json['admin_notes'] ?? json['adminNotes'])?.toString(),
      rejectionReason: (json['rejection_reason'] ?? json['rejectionReason'])
          ?.toString(),
      collectionInstructions:
          (json['collection_instructions'] ??
                  json['collectionInstructions'] ??
                  json['pickup_instructions'])
              ?.toString(),
      collectionLocation:
          (json['collection_location'] ??
                  json['collectionLocation'] ??
                  json['pickup_location'])
              ?.toString(),
      collectionDeadline: _parseDate(
        json['collection_deadline']?.toString() ??
            json['collectionDeadline']?.toString(),
      ),
      submittedAt: _parseDate(
        json['submitted_at']?.toString() ?? json['created_at']?.toString(),
      ),
      updatedAt: _parseDate(json['updated_at']?.toString()),
    );
  }

  factory ClaimRequest.fromDetail(ClaimDetail detail) {
    return ClaimRequest(
      id: detail.id,
      foundItemId: detail.itemId,
      status: detail.status,
      message: detail.message,
      foundItemTitle: detail.foundItemTitle,
      claimantContactName: detail.claimantName,
      claimantContactInfo: detail.claimantContact,
      adminNotes: detail.adminNotes,
      rejectionReason: detail.rejectionReason,
      collectionInstructions: detail.collectionInstructions,
      collectionLocation: detail.collectionLocation,
      collectionDeadline: detail.collectionDeadline,
      submittedAt: detail.submittedAt,
      updatedAt: detail.updatedAt,
    );
  }
}
