import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';
import 'package:intl/intl.dart';

class NotificationsService {
  NotificationType parseType(String raw) {
    final normalized = raw.toLowerCase().trim();
    switch (normalized) {
      // Legacy types
      case 'match_found':
        return NotificationType.matchFound;
      case 'admin_message':
        return NotificationType.adminMessage;
      case 'claim_status':
        return NotificationType.claimStatusUpdate;
      case 'system_alert':
        return NotificationType.systemAlert;

      // Student/User notification types from contract
      case 'claimsubmitted':
      case 'claim_submitted':
        return NotificationType.claimSubmitted;
      case 'claimapproved':
      case 'claim_approved':
        return NotificationType.claimApproved;
      case 'claimrejected':
      case 'claim_rejected':
        return NotificationType.claimRejected;
      case 'collectionreminder':
      case 'collection_reminder':
        return NotificationType.collectionReminder;
      case 'collectionoverdue':
      case 'collection_overdue':
        return NotificationType.collectionOverdue;
      case 'collectionexpired':
      case 'collection_expired':
        return NotificationType.collectionExpired;
      case 'collectionconfirmed':
      case 'collection_confirmed':
        return NotificationType.collectionConfirmed;

      // Admin notification types from contract
      case 'newclaim':
      case 'new_claim':
        return NotificationType.newClaim;
      case 'multipleclaims':
      case 'multiple_claims':
        return NotificationType.multipleClaims;
      case 'pendingclaimsla':
      case 'pending_claim_sla':
        return NotificationType.pendingClaimSla;
      case 'collectionoverdueadmin':
      case 'collection_overdue_admin':
        return NotificationType.collectionOverdueAdmin;
      case 'collectionreopened':
      case 'collection_reopened':
        return NotificationType.collectionReopened;
      case 'collectionarchived':
      case 'collection_archived':
        return NotificationType.collectionArchived;

      // Fallback for legacy claim status updates
      default:
        if (normalized.contains('approved')) {
          return NotificationType.claimApproved;
        }
        if (normalized.contains('rejected')) {
          return NotificationType.claimRejected;
        }
        if (normalized.contains('claim')) {
          return NotificationType.claimStatusUpdate;
        }
        return NotificationType.systemAlert;
    }
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is DateTime) return v;
    // Try ISO8601; fallback to common formats
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      try {
        return DateFormat(
          "yyyy-MM-dd HH:mm:ss",
        ).parse(v.toString(), true).toLocal();
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  Future<List<AppNotification>> fetchNotifications({int page = 1}) async {
    final res = await ApiClient.client.get(
      '/api/notifications',
      queryParameters: {'page': page},
    );
    final data = res.data;
    final List list = (data is Map && data['data'] is List)
        ? data['data'] as List
        : (data as List);
    return list.map((j) {
      final rawType = j['type']?.toString() ?? '';
      return AppNotification(
        id: j['id'].toString(),
        type: parseType(rawType),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        relatedId: j['related_id'] == null
            ? null
            : int.tryParse(j['related_id'].toString()),
        score: j['score'] == null
            ? null
            : double.tryParse(j['score'].toString()),
        createdAt: _parseDate(j['created_at']),
        readAt: j['read_at'] == null ? null : _parseDate(j['read_at']),
        rawType: rawType,
      );
    }).toList();
  }

  Future<void> markRead(String id) async {
    await ApiClient.client.post('/api/notifications/$id/read');
  }

  Future<Map<String, dynamic>> getUpdates() async {
    final res = await ApiClient.client.get('/api/notifications/updates');
    return res.data;
  }

  Future<void> markAllRead() async {
    await ApiClient.client.post('/api/notifications/mark-all-read');
  }
}
