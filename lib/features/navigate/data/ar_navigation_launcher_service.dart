import 'dart:io';
import 'package:flutter/material.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';

class ARNavigationLauncherService {
  // Unity AR app package name (from Unity ProjectSettings)
  static const String _unityAppPackageName = 'com.UnityTechnologies.com.unity.template.urpblank';

  // Unity app Play Store URL (update when published)
  static const String _unityAppPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.UnityTechnologies.com.unity.template.urpblank';

  // ARCore package name for checking support
  static const String _arcorePackageName = 'com.google.ar.core';

  /// Launch Unity AR app directly (skip ARCore check - let Unity handle it)
  static Future<void> launchARNavigation(BuildContext context) async {
    debugPrint('Attempting to launch Unity AR app...');
    debugPrint('Package name: $_unityAppPackageName');

    bool launched = false;
    String? lastError;

    // Method 1: Use external_app_launcher (most reliable for direct package launch)
    try {
      debugPrint('Method 1: Trying external_app_launcher...');
      final result = await LaunchApp.openApp(
        androidPackageName: _unityAppPackageName,
        openStore: false,
      );
      debugPrint('external_app_launcher result: $result');
      // If no exception, assume success
      launched = true;
      return;
    } catch (e) {
      lastError = e.toString();
      debugPrint('❌ external_app_launcher failed: $e');
    }

    // Method 2: Try Android Intent to launch specific package's main activity
    if (!launched) {
      try {
        debugPrint('Method 2: Trying launchPackage intent...');
        final intent = AndroidIntent(
          action: 'android.intent.action.MAIN',
          package: _unityAppPackageName,
          flags: <int>[
            Flag.FLAG_ACTIVITY_NEW_TASK,
            268435456, // FLAG_ACTIVITY_RESET_TASK_IF_NEEDED
          ],
        );
        await intent.launchChooser('Open with');
        debugPrint('✅ Launched via launchPackage intent');
        launched = true;
        return;
      } catch (e) {
        lastError = e.toString();
        debugPrint('❌ launchPackage intent failed: $e');
      }
    }

    // All methods failed - show error dialog
    if (!launched && context.mounted) {
      _showLaunchFailedDialog(context, lastError);
    }
  }

  /// Show dialog when launch fails
  static void _showLaunchFailedDialog(BuildContext context, String? error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Could Not Open AR App',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2A40),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Unable to launch the NavistFind AR app. Please make sure it is installed on your device.',
                style: TextStyle(fontSize: 15),
              ),
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Error: $error',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openPlayStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F6FEB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Download App'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  /// Check if device supports ARCore
  static Future<bool> _isARCoreSupported() async {
    if (Platform.isAndroid) {
      try {
        final isInstalled = await LaunchApp.isAppInstalled(
          androidPackageName: _arcorePackageName,
        );
        return isInstalled;
      } catch (e) {
        return true; // Assume supported if check fails
      }
    }
    return false;
  }

  /// Check if Unity AR app is installed
  static Future<bool> _isUnityAppInstalled() async {
    try {
      // Try multiple methods to check if app is installed
      final isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: _unityAppPackageName,
      );
      if (isInstalled) return true;

      // Also try to check via canLaunchUrl
      final uri = Uri.parse('android-app://$_unityAppPackageName');
      if (await canLaunchUrl(uri)) return true;

      return false;
    } catch (e) {
      debugPrint('Error checking if Unity app is installed: $e');
      return false;
    }
  }

  /// Open Play Store to install Unity AR app
  static Future<void> _openPlayStore() async {
    try {
      final playStoreUri = Uri.parse(_unityAppPlayStoreUrl);
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback: Use Android Intent
      final intent = AndroidIntent(
        action: 'android.intent.action.VIEW',
        data: _unityAppPlayStoreUrl,
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Failed to open Play Store: $e');
    }
  }

  /// Check if Unity AR app is installed (for external use)
  static Future<bool> isUnityAppInstalled() async {
    return await _isUnityAppInstalled();
  }

  /// Check if device supports ARCore (for external use)
  static Future<bool> isARCoreSupported() async {
    return await _isARCoreSupported();
  }

  /// Get Unity app package name (for external use)
  static String get unityAppPackageName => _unityAppPackageName;

  /// Get Unity app Play Store URL (for external use)
  static String get unityAppPlayStoreUrl => _unityAppPlayStoreUrl;
}
