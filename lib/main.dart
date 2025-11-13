import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'features/notifications/data/device_token_service.dart';
import 'core/secure_storage.dart';
import 'app.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Optionally refresh providers or show local notification
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Request permissions (Android 13+ shows runtime dialog)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Register current token
  final token = await messaging.getToken();
  final authToken = await SecureStorage.getToken();
  if (token != null && authToken != null) {
    try {
      await DeviceTokenService().registerToken(token);
    } catch (_) {
      // swallow errors at startup; will retry after login or on refresh
    }
  }
  // Keep server in sync when token rotates
  FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
    final authToken2 = await SecureStorage.getToken();
    if (authToken2 != null) {
      try {
        await DeviceTokenService().registerToken(t);
      } catch (_) {}
    }
  });
  runApp(const ProviderScope(child: MyApp()));
}
