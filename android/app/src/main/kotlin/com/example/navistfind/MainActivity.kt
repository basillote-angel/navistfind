package com.example.navistfind

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.PackageInfo
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.navistfind/app_launcher"
    private val TAG = "ARAppLauncher"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        Log.d(TAG, "Attempting to launch: $packageName")
                        val launchResult = launchApp(packageName)
                        if (launchResult.first) {
                            result.success(true)
                        } else {
                            result.error("LAUNCH_FAILED", launchResult.second, null)
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "isAppInstalled" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val installed = isAppInstalled(packageName)
                        Log.d(TAG, "Is $packageName installed: $installed")
                        result.success(installed)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "getInstalledPackages" -> {
                    val packages = getInstalledPackageNames()
                    result.success(packages)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun launchApp(packageName: String): Pair<Boolean, String> {
        Log.d(TAG, "========================================")
        Log.d(TAG, "launchApp called with: $packageName")
        Log.d(TAG, "========================================")

        // Skip install check - just try to launch directly
        // Method 1: Use getLaunchIntentForPackage
        try {
            Log.d(TAG, "Method 1: Trying getLaunchIntentForPackage")
            val intent: Intent? = packageManager.getLaunchIntentForPackage(packageName)
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                Log.d(TAG, "✅ Launched via getLaunchIntentForPackage")
                return Pair(true, "Success")
            } else {
                Log.d(TAG, "getLaunchIntentForPackage returned null")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Method 1 failed: ${e.message}")
        }

        // Method 2: Try with ACTION_MAIN and CATEGORY_LAUNCHER
        try {
            Log.d(TAG, "Method 2: Trying ACTION_MAIN with LAUNCHER category")
            val intent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_LAUNCHER)
                setPackage(packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val activities = packageManager.queryIntentActivities(intent, 0)
            Log.d(TAG, "Found ${activities.size} launcher activities")
            if (activities.isNotEmpty()) {
                startActivity(intent)
                Log.d(TAG, "✅ Launched via ACTION_MAIN")
                return Pair(true, "Success")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Method 2 failed: ${e.message}")
        }

        // Method 3: Try Unity's GameActivity (newer Unity versions)
        try {
            Log.d(TAG, "Method 3: Trying UnityPlayerGameActivity")
            val intent = Intent().apply {
                setClassName(packageName, "com.unity3d.player.UnityPlayerGameActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
            Log.d(TAG, "✅ Launched via UnityPlayerGameActivity")
            return Pair(true, "Success")
        } catch (e: Exception) {
            Log.e(TAG, "Method 3 failed: ${e.message}")
        }

        // Method 4: Try to get any activity from the package
        try {
            Log.d(TAG, "Method 4: Trying to find any activity")
            val packageInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(PackageManager.GET_ACTIVITIES.toLong()))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, PackageManager.GET_ACTIVITIES)
            }

            val activities = packageInfo.activities
            if (activities != null && activities.isNotEmpty()) {
                Log.d(TAG, "Found ${activities.size} activities in package")
                val activityName = activities[0].name
                Log.d(TAG, "Trying to launch: $activityName")
                val intent = Intent().apply {
                    setClassName(packageName, activityName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                startActivity(intent)
                Log.d(TAG, "✅ Launched via direct activity: $activityName")
                return Pair(true, "Success")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Method 4 failed: ${e.message}")
        }

        return Pair(false, "All launch methods failed for $packageName")
    }

    private fun isAppInstalled(packageName: String): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0))
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
            }
            true
        } catch (e: PackageManager.NameNotFoundException) {
            Log.d(TAG, "Package not found: $packageName")
            false
        }
    }

    private fun getInstalledPackageNames(): List<String> {
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledPackages(PackageManager.PackageInfoFlags.of(0))
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledPackages(0)
        }
        // Return packages that might be related to Unity/AR/NavistFind
        // Broader search to find the app
        return packages.map { it.packageName }.filter {
            it.contains("unity", ignoreCase = true) ||
            it.contains("navist", ignoreCase = true) ||
            it.contains("ar", ignoreCase = true) ||
            it.contains("navigation", ignoreCase = true) ||
            it.contains("campus", ignoreCase = true) ||
            it.contains("find", ignoreCase = true) ||
            it.contains("DefaultCompany", ignoreCase = true) ||  // Unity default company
            it.contains("urp", ignoreCase = true) ||
            it.contains("template", ignoreCase = true)
        }.sorted()
    }
}
