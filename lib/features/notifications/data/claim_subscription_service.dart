import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class ClaimSubscriptionService {
  ClaimSubscriptionService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  Future<void> subscribeToClaimUpdates({required int itemId}) async {
    final topic = 'claim-status-item-$itemId';
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (error, stackTrace) {
      debugPrint(
        'ClaimSubscriptionService: Failed to subscribe to $topic -> $error\n$stackTrace',
      );
    }
  }
}



