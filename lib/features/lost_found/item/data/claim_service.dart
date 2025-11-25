import 'package:dio/dio.dart';
import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/core/constants.dart';
import 'package:navistfind/features/lost_found/item/domain/models/claim_detail.dart';

class ClaimService {
  ClaimService({Dio? client}) : _client = client ?? ApiClient.client;

  final Dio _client;

  /// Fetch claim details by item ID
  /// Note: The backend embeds claim information in the item response
  Future<ClaimDetail> fetchClaimDetail(int itemId) async {
    try {
      print('[ClaimService] Fetching claim detail for item ID: $itemId');
      // Fetch item details which includes claim information embedded in the item
      final response = await _client.get('/api/items/$itemId');
      print('[ClaimService] Response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> itemData;

        // Handle response structure (could be wrapped in 'data' key)
        if (data is Map<String, dynamic>) {
          itemData = data['data'] is Map
              ? Map<String, dynamic>.from(data['data'])
              : data;
        } else if (data is Map) {
          itemData = Map<String, dynamic>.from(data);
        } else {
          throw const FormatException('Unexpected item response shape.');
        }

        // Check if item has a claim (has claimed_by or status indicates claim)
        final itemStatus = itemData['status']?.toString().toUpperCase() ?? '';
        final hasClaim =
            itemData['claimed_by'] != null ||
            itemData['claimed_by_id'] != null ||
            itemData['claim'] != null ||
            itemData['claims'] != null ||
            itemStatus.contains('CLAIM');

        if (!hasClaim &&
            (itemStatus == 'FOUND_UNCLAIMED' || itemStatus == 'FOUND')) {
          throw DioException(
            requestOptions: RequestOptions(path: '/api/items/$itemId'),
            error: 'No active claim found for this item',
          );
        }

        // Try to get claim from nested relationships first
        Map<String, dynamic>? nestedClaim;
        if (itemData['claim'] is Map) {
          nestedClaim = Map<String, dynamic>.from(itemData['claim'] as Map);
        } else if (itemData['claims'] is List &&
            (itemData['claims'] as List).isNotEmpty) {
          final claimsList = itemData['claims'] as List;
          nestedClaim = Map<String, dynamic>.from(claimsList.first as Map);
        }

        // Build claim JSON from item data
        // Prefer nested claim data if available, otherwise use item fields
        final sourceData = nestedClaim ?? itemData;

        final claimId =
            sourceData['id'] ??
            sourceData['claim_id'] ??
            sourceData['claimed_item_id'] ??
            itemData['id'] ??
            itemId;

        // Determine claim status - prefer nested claim status, then map from item status
        String claimStatusStr;
        if (nestedClaim != null && nestedClaim['status'] != null) {
          claimStatusStr = nestedClaim['status'].toString();
        } else {
          claimStatusStr = _mapItemStatusToClaimStatus(itemStatus);
        }

        final claimJson = <String, dynamic>{
          // Claim ID - use item ID as fallback if no separate claim ID
          'id': claimId,
          'item_id': itemId,

          // Claim status
          'status': claimStatusStr,

          // Claim message - required field
          'message':
              (sourceData['message'] ??
                      sourceData['claim_message'] ??
                      itemData['claim_message'] ??
                      itemData['message'] ??
                      '')
                  .toString(),

          // Submitted at - required field, use claimed_at or created_at
          'submitted_at':
              sourceData['submitted_at'] ??
              sourceData['submittedAt'] ??
              sourceData['created_at'] ??
              sourceData['createdAt'] ??
              itemData['claimed_at'] ??
              itemData['claimedAt'] ??
              itemData['created_at'] ??
              itemData['createdAt'] ??
              DateTime.now().toIso8601String(),
        };

        // Add optional fields if they exist (check nested claim first, then item)
        if (sourceData['updated_at'] != null ||
            sourceData['updatedAt'] != null) {
          claimJson['updated_at'] =
              sourceData['updated_at'] ?? sourceData['updatedAt'];
        } else if (itemData['updated_at'] != null ||
            itemData['updatedAt'] != null) {
          claimJson['updated_at'] =
              itemData['updated_at'] ?? itemData['updatedAt'];
        }

        if (itemData['title'] != null || itemData['name'] != null) {
          claimJson['found_item'] = {
            'title': (itemData['title'] ?? itemData['name']).toString(),
          };
        }

        // Claimant information
        final claimantName =
            sourceData['claimant_name'] ??
            sourceData['claimantName'] ??
            sourceData['claimant']?['name'] ??
            itemData['claimant_contact_name'] ??
            itemData['claimant_name'];
        if (claimantName != null) {
          claimJson['claimant_name'] = claimantName.toString();
        }

        final claimantContact =
            sourceData['claimant_contact'] ??
            sourceData['claimantContact'] ??
            sourceData['claimant_contact_info'] ??
            sourceData['claimantContactInfo'] ??
            sourceData['claimant']?['contactInfo'] ??
            sourceData['claimant']?['contact'] ??
            itemData['claimant_contact_info'] ??
            itemData['claimant_contact'];
        if (claimantContact != null) {
          claimJson['claimant_contact'] = claimantContact.toString();
        }

        // Admin notes
        final adminNotes =
            sourceData['admin_notes'] ??
            sourceData['adminNotes'] ??
            itemData['admin_notes'] ??
            itemData['adminNotes'];
        if (adminNotes != null) {
          claimJson['admin_notes'] = adminNotes.toString();
        }

        // Rejection reason
        final rejectionReason =
            sourceData['rejection_reason'] ??
            sourceData['rejectionReason'] ??
            itemData['rejection_reason'] ??
            itemData['rejectionReason'];
        if (rejectionReason != null) {
          claimJson['rejection_reason'] = rejectionReason.toString();
        }

        // Collection information
        final collectionInstructions =
            sourceData['collection_instructions'] ??
            sourceData['collectionInstructions'] ??
            sourceData['pickup_instructions'] ??
            sourceData['pickupInstructions'] ??
            itemData['collection_instructions'] ??
            itemData['collectionInstructions'] ??
            itemData['pickup_instructions'] ??
            itemData['pickupInstructions'];
        if (collectionInstructions != null) {
          claimJson['collection_instructions'] = collectionInstructions
              .toString();
        }

        final collectionLocation =
            sourceData['collection_location'] ??
            sourceData['collectionLocation'] ??
            sourceData['pickup_location'] ??
            sourceData['pickupLocation'] ??
            itemData['collection_location'] ??
            itemData['collectionLocation'] ??
            itemData['pickup_location'] ??
            itemData['pickupLocation'];
        if (collectionLocation != null) {
          claimJson['collection_location'] = collectionLocation.toString();
        }

        final collectionDeadline =
            sourceData['collection_deadline'] ??
            sourceData['collectionDeadline'] ??
            itemData['collection_deadline'] ??
            itemData['collectionDeadline'];
        if (collectionDeadline != null) {
          claimJson['collection_deadline'] = collectionDeadline.toString();
        }

        // Claim image
        final claimImage =
            sourceData['claim_image'] ??
            sourceData['claimImage'] ??
            itemData['claim_image'] ??
            itemData['claimImage'];
        if (claimImage != null) {
          claimJson['claim_image'] = claimImage.toString();
          // Generate full URL if not provided
          final imageUrl =
              sourceData['claim_image_url'] ??
              sourceData['claimImageUrl'] ??
              itemData['claim_image_url'] ??
              itemData['claimImageUrl'];
          claimJson['claim_image_url'] =
              imageUrl?.toString() ??
              '${Constants.backendBaseUrl}/storage/${claimImage.toString()}';
        }

        print('[ClaimService] Built claim JSON: $claimJson');
        try {
          final claimDetail = ClaimDetail.fromJson(claimJson);
          print(
            '[ClaimService] Successfully parsed claim detail: id=${claimDetail.id}, status=${claimDetail.status}',
          );
          return claimDetail;
        } catch (e, stackTrace) {
          print(
            '[ClaimService] Error parsing claim detail from item $itemId: $e',
          );
          print('[ClaimService] Item data keys: ${itemData.keys.toList()}');
          print('[ClaimService] Claim JSON: $claimJson');
          print('[ClaimService] Stack trace: $stackTrace');
          throw DioException(
            requestOptions: RequestOptions(path: '/api/items/$itemId'),
            error: 'Failed to parse claim detail: $e. Check logs for details.',
            stackTrace: stackTrace,
          );
        }
      }
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: 'Failed to load claim detail (status: ${response.statusCode})',
      );
    } on DioException {
      rethrow;
    } catch (error, stackTrace) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/items/$itemId'),
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _mapItemStatusToClaimStatus(String itemStatus) {
    final upper = itemStatus.toUpperCase();
    if (upper == 'CLAIM_PENDING' || upper.contains('PENDING')) {
      return 'PENDING';
    } else if (upper == 'CLAIM_APPROVED' || upper.contains('APPROVED')) {
      return 'APPROVED';
    } else if (upper.contains('REJECTED')) {
      return 'REJECTED';
    } else if (upper.contains('WITHDRAWN') || upper.contains('CANCELLED')) {
      return 'WITHDRAWN';
    }
    // Default to pending if status indicates a claim exists
    if (upper.contains('CLAIM')) {
      return 'PENDING';
    }
    return 'PENDING';
  }

  Future<void> updateClaim({
    required int itemId,
    String? message,
    String? contactName,
    String? contactInfo,
  }) async {
    final payload = <String, dynamic>{};
    if (message != null) payload['message'] = message;
    if (contactName != null) payload['contactName'] = contactName;
    if (contactInfo != null) payload['contactInfo'] = contactInfo;

    await _client.put('/api/items/$itemId/claim', data: payload);
  }

  Future<void> cancelClaim({required int itemId, int? claimId}) async {
    // Try DELETE on claim endpoint first if we have claimId
    if (claimId != null && claimId > 0) {
      try {
        await _client.delete('/api/claims/$claimId');
        return;
      } catch (e) {
        // If DELETE on /api/claims/{id} fails, try DELETE on /api/items/{id}/claim
        try {
          await _client.delete('/api/items/$itemId/claim');
          return;
        } catch (_) {
          // Fall through to POST method
        }
      }
    }

    // Fallback: Try DELETE on /api/items/{id}/claim
    try {
      await _client.delete('/api/items/$itemId/claim');
      return;
    } catch (_) {
      // Last resort: POST with withdraw action (may create new claim, but backend might handle it)
      await _client.post(
        '/api/items/$itemId/claim',
        data: {
          'message': 'Requesting to cancel/withdraw this claim.',
          'action': 'cancel',
          'withdraw': true,
        },
      );
    }
  }
}
