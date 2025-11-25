import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/secure_storage.dart';
import 'features/notifications/data/device_token_service.dart';

Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // App already initialized in main isolate. Add background-specific work here if needed.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  // Request permissions (Android 13+ shows runtime dialog)
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Register current token
  final currentToken = await messaging.getToken();
  final authToken = await SecureStorage.getToken();
  if (currentToken != null && authToken != null) {
    unawaited(_registerDeviceToken(currentToken));
  }
  // Keep server in sync when token rotates
  FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
    final authToken2 = await SecureStorage.getToken();
    if (authToken2 != null) {
      unawaited(_registerDeviceToken(t));
    }
  });
  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _registerDeviceToken(String token) async {
  try {
    await DeviceTokenService().registerToken(token);
  } catch (_) {
    // best-effort sync; ignore failures
  }
}
