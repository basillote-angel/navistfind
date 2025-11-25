import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:navistfind/features/notifications/data/notifications_service.dart';
import 'package:navistfind/features/notifications/domain/notification.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService();
});

final notificationsProvider =
    StateNotifierProvider<
      NotificationsNotifier,
      AsyncValue<List<AppNotification>>
    >((ref) => NotificationsNotifier(ref));

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsNotifier(this._read) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _read;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final list = await _read
          .read(notificationsServiceProvider)
          .fetchNotifications();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markRead(String id) async {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current
          .map((n) => n.id == id ? n.copyWith(readAt: DateTime.now()) : n)
          .toList(),
    );
    await _read.read(notificationsServiceProvider).markRead(id);
  }
}
