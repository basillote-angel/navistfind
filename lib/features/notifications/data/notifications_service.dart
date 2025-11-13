import 'package:navistfind/core/network/api_client.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';
import 'package:intl/intl.dart';

class NotificationsService {
  NotificationType _parseType(String raw) {
    switch (raw) {
      case 'match_found':
        return NotificationType.matchFound;
      case 'admin_message':
        return NotificationType.adminMessage;
      case 'claim_status':
      case 'claimApproved':
      case 'claimRejected':
        return NotificationType.claimStatusUpdate;
      case 'newClaim':
      case 'new_claim':
        return NotificationType.newClaim;
      case 'system_alert':
      case 'multipleClaims':
      default:
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
      return AppNotification(
        id: j['id'].toString(),
        type: _parseType(j['type']?.toString() ?? ''),
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
