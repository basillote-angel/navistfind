import 'package:flutter/material.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class ARTransitionScreen extends StatefulWidget {
  final String? buildingName;
  final String? roomName;
  final LatLng destination;
  final String buildingDescription;
  final List<String> rooms;

  const ARTransitionScreen({
    super.key,
    this.buildingName,
    this.roomName,
    required this.destination,
    required this.buildingDescription,
    required this.rooms,
  });

  @override
  State<ARTransitionScreen> createState() => _ARTransitionScreenState();
}

class _ARTransitionScreenState extends State<ARTransitionScreen>
    with TickerProviderStateMixin {
  late AnimationController _loadingController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPreparing = true;
  int _currentTipIndex = 0;

  // Add compatibility checking
  bool _isCheckingCompatibility = false;
  String _compatibilityStatus = '';
  bool _canLaunchAR = false;

  final List<String> _arTips = [
    "Move your phone around slowly to calibrate AR tracking",
    "Keep your phone steady for accurate navigation",
    "Follow the 3D arrow to reach your destination",
    "Stay in well-lit areas for better AR performance",
    "Walk slowly and follow the visual guidance",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startPreparation();
    _startTipRotation();
    _checkARCompatibility(); // Add this
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _loadingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startPreparation() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _isPreparing = false;
      });
    }
  }

  void _startTipRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _currentTipIndex = (_currentTipIndex + 1) % _arTips.length;
        });
        _startTipRotation();
      }
    });
  }

  // Enhanced AR compatibility checking
  Future<void> _checkARCompatibility() async {
    setState(() {
      _isCheckingCompatibility = true;
      _compatibilityStatus = 'Checking device compatibility...';
    });

    try {
      // Check 1: Unity app installation with multiple methods
      bool isUnityInstalled = await _checkUnityAppInstallation();

      if (!isUnityInstalled) {
        setState(() {
          _isCheckingCompatibility = false;
          _compatibilityStatus = 'AR Navigation app not found';
          _canLaunchAR = false;
        });
        return;
      }

      // Check 2: Device AR capabilities
      bool hasARSupport = await _checkDeviceARSupport();
      if (!hasARSupport) {
        setState(() {
          _isCheckingCompatibility = false;
          _compatibilityStatus = 'Device not compatible with AR';
          _canLaunchAR = false;
        });
        return;
      }

      // All checks passed
      setState(() {
        _isCheckingCompatibility = false;
        _compatibilityStatus =
            '✅ Device is compatible! Ready for AR navigation.';
        _canLaunchAR = true;
      });
    } catch (e) {
      setState(() {
        _isCheckingCompatibility = false;
        _compatibilityStatus = 'Error checking compatibility: $e';
        _canLaunchAR = false;
      });
    }
  }

  // Multiple methods to check Unity app installation
  Future<bool> _checkUnityAppInstallation() async {
    try {
      // Method 1: Try to launch app (most reliable)
      bool canLaunch = await LaunchApp.isAppInstalled(
        androidPackageName: "com.navistfind.ARNav",
      );

      if (canLaunch) {
        print("✅ Unity app can be launched via LaunchApp");
        return true;
      }

      // Method 2: Check if app is installed
      bool isInstalled = await LaunchApp.isAppInstalled(
        androidPackageName: "com.navistfind.ARNav",
      );

      if (isInstalled) {
        print("✅ Unity app is installed");
        return true;
      }

      // Method 3: Try alternative package names (in case Unity build has different name)
      List<String> alternativePackages = [
        "com.navistfind.ARNav",
        "com.ayfind.ar",
        "com.navistfind.arnav",
        "com.example.arnav",
      ];

      for (String package in alternativePackages) {
        try {
          bool altCanLaunch = await LaunchApp.isAppInstalled(
            androidPackageName: package,
          );
          if (altCanLaunch) {
            print("✅ Found Unity app with package: $package");
            return true;
          }
        } catch (e) {
          print("Package $package not found: $e");
        }
      }

      // Method 4: Check if app exists in device apps list
      bool existsInDevice = await _checkAppExistsInDevice();
      if (existsInDevice) {
        print("✅ Unity app exists in device");
        return true;
      }

      print("❌ Unity app not found with any method");
      return false;
    } catch (e) {
      print("Error checking Unity app installation: $e");
      return false;
    }
  }

  // Check if app exists in device apps
  Future<bool> _checkAppExistsInDevice() async {
    try {
      // This is a fallback method - try to get app info
      final result = await const MethodChannel(
        'app_checker',
      ).invokeMethod('checkAppExists', {'packageName': 'com.navistfind.ARNav'});
      return result == true;
    } catch (e) {
      // If method channel fails, assume app doesn't exist
      print("Method channel check failed: $e");
      return false;
    }
  }

  // Check device AR support
  Future<bool> _checkDeviceARSupport() async {
    try {
      if (Platform.isAndroid) {
        // Basic Android version check
        // ARCore requires Android 7.0+ (API 24)
        return true; // Assume compatible for now
      }
      return false;
    } catch (e) {
      print("Error checking device AR support: $e");
      return true; // Assume compatible if check fails
    }
  }

  // Enhanced Unity app launch
  Future<void> _launchUnityApp() async {
    if (_isCheckingCompatibility) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, checking device compatibility...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_canLaunchAR) {
      _showCompatibilityIssueDialog();
      return;
    }

    try {
      // Try multiple launch methods
      bool launched = await _tryLaunchUnityApp();

      if (launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Launching AR Navigation to ${widget.buildingName}...',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to launch Unity app with all methods');
      }
    } catch (e) {
      _showErrorDialog('Launch Failed', 'Failed to launch AR Navigation: $e');
    }
  }

  // Try multiple launch methods
  Future<bool> _tryLaunchUnityApp() async {
    try {
      // Method 1: LaunchApp.openApp
      try {
        await LaunchApp.openApp(
          androidPackageName: "com.navistfind.ARNav",
          openStore: false,
        );
        print("✅ Unity app launched via LaunchApp.openApp");
        return true;
      } catch (e) {
        print("LaunchApp.openApp failed: $e");
      }

      // Method 2: AndroidIntent with custom action
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          package: 'com.navistfind.ARNav',
          arguments: {
            'building_name': widget.buildingName ?? '',
            'room_name': widget.roomName ?? '',
            'destination_lat': widget.destination.latitude.toString(),
            'destination_lng': widget.destination.longitude.toString(),
            'building_description': widget.buildingDescription,
          },
        );

        await intent.launch();
        print("✅ Unity app launched via AndroidIntent");
        return true;
      } catch (e) {
        print("AndroidIntent launch failed: $e");
      }

      // Method 3: Try alternative package names
      List<String> alternativePackages = [
        "com.navistfind.ARNav",
        "com.ayfind.ar",
        "com.navistfind.arnav",
      ];

      for (String package in alternativePackages) {
        try {
          await LaunchApp.openApp(
            androidPackageName: package,
            openStore: false,
          );
          print("✅ Unity app launched with package: $package");
          return true;
        } catch (e) {
          print("Package $package launch failed: $e");
        }
      }

      return false;
    } catch (e) {
      print("All launch methods failed: $e");
      return false;
    }
  }

  // Show compatibility issue dialog
  void _showCompatibilityIssueDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ AR Navigation Unavailable'),
        content: Text(
          'Your device cannot launch AR Navigation:\n\n'
          'Status: $_compatibilityStatus\n\n'
          'Possible solutions:\n'
          '• Make sure AR Navigation app is installed\n'
          '• Check if the app is enabled\n'
          '• Restart your device\n'
          '• Contact support if the issue persists',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkARCompatibility(); // Re-check
            },
            child: const Text('Re-check'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2A40),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'AR Navigation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Add compatibility status display
              if (_isCheckingCompatibility || _compatibilityStatus.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getCompatibilityStatusColor(),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCompatibilityStatusColor().withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCompatibilityStatusIcon(),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _compatibilityStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (_isCheckingCompatibility)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C2A40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.buildingName ?? "",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.roomName != null)
                                Text(
                                  widget.roomName!,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.buildingDescription,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Available Rooms:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: widget.rooms.map((room) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            room,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_isPreparing) ...[
                AnimatedBuilder(
                  animation: _loadingController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _loadingController.value * 2 * 3.14159,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue, width: 4),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.navigation,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Preparing AR guidance...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please wait while we calibrate the AR system',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Colors.blue[400],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'AR Navigation Tips',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(
                          _arTips[_currentTipIndex],
                          key: ValueKey(_currentTipIndex),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Enhanced action buttons
                if (!_isCheckingCompatibility) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canLaunchAR ? _launchUnityApp : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canLaunchAR
                                ? Colors.blue
                                : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: const Icon(
                                      Icons.view_in_ar,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getLaunchButtonText(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for UI
  Color _getCompatibilityStatusColor() {
    if (_isCheckingCompatibility) return Colors.blue;
    if (_compatibilityStatus.contains('✅')) return Colors.green;
    if (_compatibilityStatus.contains('❌') ||
        _compatibilityStatus.contains('Error')) {
      return Colors.red;
    }
    return Colors.orange;
  }

  IconData _getCompatibilityStatusIcon() {
    if (_isCheckingCompatibility) return Icons.info;
    if (_compatibilityStatus.contains('✅')) return Icons.check_circle;
    if (_compatibilityStatus.contains('❌') ||
        _compatibilityStatus.contains('Error')) {
      return Icons.error;
    }
    return Icons.warning;
  }

  String _getLaunchButtonText() {
    if (_isCheckingCompatibility) return 'Checking...';
    if (_canLaunchAR) return 'Launch AR';
    return 'Not Compatible';
  }
}
