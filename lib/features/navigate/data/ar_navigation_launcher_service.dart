import 'dart:io';
import 'package:flutter/material.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:android_intent_plus/android_intent.dart';

class ARNavigationLauncherService {
  // Unity AR app package name - update this with your actual Unity app package name
  static const String _unityAppPackageName = 'com.navistfind.ARNav';

  // Unity app Play Store URL - update this with your actual Play Store URL
  static const String _unityAppPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=com.navistfind.ARNav';

  // ARCore package name for checking support
  static const String _arcorePackageName = 'com.google.ar.core';

  /// Check if device supports ARCore and launch Unity AR app
  static Future<void> launchARNavigation(BuildContext context) async {
    // First check ARCore support
    if (!await _isARCoreSupported()) {
      _showARNotSupportedDialog(context);
      return;
    }

    // Try to launch Unity app directly (bypass detection issues)
    try {
      debugPrint('Attempting to launch Unity AR app directly...');
      await _launchUnityApp();
    } catch (e) {
      debugPrint('Direct launch failed, trying intent-based launch: $e');
      // If direct launch fails, try intent-based launch
      await _launchUnityAppViaIntent();
    }
  }

  /// Check if device supports ARCore
  static Future<bool> _isARCoreSupported() async {
    if (Platform.isAndroid) {
      try {
        // Check if ARCore is available
        final isInstalled = await LaunchApp.isAppInstalled(
          androidPackageName: _arcorePackageName,
        );

        if (isInstalled) {
          return true;
        }

        // Check if device supports ARCore but it's not installed
        // This would require additional device capability checking
        // For now, we'll use a simple check
        return await _checkARCoreCompatibility();
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Check ARCore compatibility using device info
  static Future<bool> _checkARCoreCompatibility() async {
    try {
      // This is a simplified check - in production you might want to use
      // device_info_plus package for more detailed device capability checking
      return true; // Assume compatible for now
    } catch (e) {
      return false;
    }
  }

  /// Check if Unity AR app is installed
  static Future<bool> _isUnityAppInstalled() async {
    try {
      return await LaunchApp.isAppInstalled(
        androidPackageName: _unityAppPackageName,
      );
    } catch (e) {
      return false;
    }
  }

  /// Launch Unity AR app with multiple fallback methods
  static Future<void> _launchUnityApp() async {
    debugPrint('Attempting to launch Unity AR app: $_unityAppPackageName');

    // Method 1: Try LaunchApp.openApp
    try {
      debugPrint('Method 1: Trying LaunchApp.openApp...');
      await LaunchApp.openApp(
        androidPackageName: _unityAppPackageName,
        openStore: false,
      );
      debugPrint('✅ Unity app launched successfully via LaunchApp');
      return;
    } catch (e) {
      debugPrint('❌ LaunchApp.openApp failed: $e');
    }

    // Method 2: Try LaunchApp.isAppInstalled + openApp
    try {
      debugPrint('Method 2: Trying LaunchApp.isAppInstalled...');
      bool isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: _unityAppPackageName,
      );
      if (isInstalled) {
        debugPrint('✅ Unity app is installed, trying to open...');
        await LaunchApp.openApp(
          androidPackageName: _unityAppPackageName,
          openStore: false,
        );
        debugPrint('✅ Unity app opened successfully');
        return;
      } else {
        debugPrint('❌ Unity app not found via LaunchApp.isAppInstalled');
      }
    } catch (e) {
      debugPrint('❌ LaunchApp.isAppInstalled failed: $e');
    }

    // Method 3: Try Android Intent with different actions
    try {
      debugPrint('Method 3: Trying Android Intent...');
      await _launchUnityAppViaIntent();
      return;
    } catch (e) {
      debugPrint('❌ Android Intent failed: $e');
    }

    // Method 4: Try alternative package names
    try {
      debugPrint('Method 4: Trying alternative package names...');
      await _tryAlternativePackageNames();
      return;
    } catch (e) {
      debugPrint('❌ Alternative package names failed: $e');
    }

    // All methods failed
    debugPrint('❌ All launch methods failed. Unity app cannot be launched.');
    throw Exception('Failed to launch Unity AR app after trying all methods');
  }

  /// Fallback method to launch Unity app via Android Intent
  static Future<void> _launchUnityAppViaIntent() async {
    try {
      debugPrint('Trying Android Intent launch...');

      // Try different intent actions
      List<String> actions = [
        'action_view',
        'android.intent.action.VIEW',
        'android.intent.action.MAIN',
      ];

      for (String action in actions) {
        try {
          debugPrint('Trying action: $action');
          final AndroidIntent intent = AndroidIntent(
            action: action,
            package: _unityAppPackageName,
            data: 'navistfind://ar-navigation',
          );
          await intent.launch();
          debugPrint(
            '✅ Unity app launched via Android Intent with action: $action',
          );
          return;
        } catch (e) {
          debugPrint('❌ Action $action failed: $e');
        }
      }

      throw Exception('All Android Intent actions failed');
    } catch (e) {
      debugPrint('❌ Android Intent launch completely failed: $e');
      rethrow;
    }
  }

  /// Try alternative package names in case Unity has different naming
  static Future<void> _tryAlternativePackageNames() async {
    List<String> alternativePackages = [
      'com.navistfind.ARNav',
      'com.navistfind.arnav',
      'com.navistfind.ar.navigation',
      'com.example.navistfind.ar.navigation',
      'com.navistfind.arnavigation',
    ];

    for (String package in alternativePackages) {
      try {
        debugPrint('Trying alternative package: $package');
        bool isInstalled = await LaunchApp.isAppInstalled(
          androidPackageName: package,
        );
        if (isInstalled) {
          debugPrint('✅ Found Unity app with package: $package');
          await LaunchApp.openApp(
            androidPackageName: package,
            openStore: false,
          );
          debugPrint('✅ Unity app launched with alternative package: $package');
          return;
        }
      } catch (e) {
        debugPrint('❌ Alternative package $package failed: $e');
      }
    }

    throw Exception('No alternative package names worked');
  }

  /// Show dialog when AR is not supported
  static void _showARNotSupportedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'AR Navigation Not Supported',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2A40),
            ),
          ),
          content: const Text(
            'Your device does not support AR Navigation. You can still use the map view for guidance.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFF1C2A40),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  /// Show dialog to install AR module
  static void _showInstallARModuleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Install AR Module',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1C2A40),
            ),
          ),
          content: const Text(
            'AR Navigation requires the NavistFind AR module. Would you like to install it now?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _openPlayStore();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1C2A40),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Install',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  /// Open Play Store to install Unity AR app
  static Future<void> _openPlayStore() async {
    try {
      // Use Android Intent to open Play Store
      final AndroidIntent intent = AndroidIntent(
        action: 'action_view',
        data: _unityAppPlayStoreUrl,
        package: 'com.android.vending', // Play Store package
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Failed to open Play Store: $e');
      // Fallback: try to open with external app launcher
      try {
        await LaunchApp.openApp(
          androidPackageName: 'com.android.vending',
          openStore: false,
        );
      } catch (fallbackError) {
        debugPrint('Fallback Play Store launch failed: $fallbackError');
      }
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
