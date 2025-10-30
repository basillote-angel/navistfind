import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import '../../../core/theme/app_theme.dart';
import '../data/ar_navigation_service.dart';
import '../data/ar_navigation_launcher_service.dart';
import 'ar_navigation_conditional_widget.dart';

class ARNavigationScreen extends StatefulWidget {
  final String buildingName;
  final LatLng destination;

  const ARNavigationScreen({
    super.key,
    required this.buildingName,
    required this.destination,
  });

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;

  Position? currentPosition;
  bool isNavigating = false;
  String navigationText = '';
  double? bearing;
  double? distance;

  // Animation controllers for smooth arrow movement
  late AnimationController _arrowAnimationController;
  late Animation<double> _arrowRotationAnimation;

  // Timer for continuous updates
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimationControllers();
    _initializeCamera();
    _requestPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _arrowAnimationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _initializeAnimationControllers() {
    _arrowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _arrowRotationAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _arrowAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _cameraController = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final camController = _cameraController;
    if (camController == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      camController.dispose();
      setState(() {
        _cameraController = null;
      });
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text('AR Navigation to ${widget.buildingName}'),
          backgroundColor: AppTheme.primaryBlue,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('AR Navigation to ${widget.buildingName}'),
        backgroundColor: AppTheme.primaryBlue,
        actions: [
          ConditionalARIconButton(
            onPressed: () => _launchUnityARNavigation(),
            tooltip: 'Launch Unity AR App',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _startNavigation(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(_cameraController!),

          // AR Navigation overlay with dynamic arrow
          if (isNavigating && bearing != null) _buildDynamicNavigationOverlay(),

          // Control panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Navigating to: ${widget.buildingName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    navigationText,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: isNavigating ? null : _startNavigation,
                        child: const Text('Start Navigation'),
                      ),
                      ElevatedButton(
                        onPressed: _stopNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicNavigationOverlay() {
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: AnimatedBuilder(
        animation: _arrowRotationAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: DynamicNavigationPainter(
              bearing: bearing!,
              distance: distance!,
              buildingName: widget.buildingName,
              arrowRotation: _arrowRotationAnimation.value,
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestPermissions() async {
    bool hasPermissions = await ARNavigationService.requestPermissions();
    if (hasPermissions) {
      _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera and location permissions are required for AR navigation',
          ),
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await ARNavigationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        currentPosition = position;
      });
      _startNavigation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location')),
      );
    }
  }

  void _startContinuousUpdates() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isNavigating && mounted) {
        _updateNavigationData();
      }
    });
  }

  void _updateNavigationData() async {
    if (currentPosition == null) return;

    LatLng current = LatLng(
      currentPosition!.latitude,
      currentPosition!.longitude,
    );
    double newDistance = ARNavigationService.calculateDistance(
      current,
      widget.destination,
    );
    double newBearing = ARNavigationService.calculateBearing(
      current,
      widget.destination,
    );

    // Animate arrow rotation smoothly
    _animateArrowRotation(newBearing);

    setState(() {
      distance = newDistance;
      bearing = newBearing;
      navigationText =
          'Distance: ${newDistance.toStringAsFixed(1)}m\nBearing: ${newBearing.toStringAsFixed(1)}°\n\nFollow the arrow to reach your destination!';
    });
  }

  void _animateArrowRotation(double newBearing) {
    double currentRotation = _arrowRotationAnimation.value;
    double targetRotation = newBearing * (pi / 180);

    // Calculate shortest rotation path
    double rotationDiff = targetRotation - currentRotation;
    if (rotationDiff > pi) rotationDiff -= 2 * pi;
    if (rotationDiff < -pi) rotationDiff += 2 * pi;

    _arrowRotationAnimation =
        Tween<double>(
          begin: currentRotation,
          end: currentRotation + rotationDiff,
        ).animate(
          CurvedAnimation(
            parent: _arrowAnimationController,
            curve: Curves.easeInOut,
          ),
        );

    _arrowAnimationController.forward(from: 0.0);
  }

  Future<void> _startNavigation() async {
    if (currentPosition == null) {
      await _getCurrentLocation();
      return;
    }

    setState(() {
      isNavigating = true;
    });

    _updateNavigationData();
    _startContinuousUpdates();
  }

  void _stopNavigation() {
    setState(() {
      isNavigating = false;
      navigationText = '';
      bearing = null;
      distance = null;
    });

    _updateTimer?.cancel();
    _arrowAnimationController.stop();
  }

  /// Launch Unity AR navigation app
  Future<void> _launchUnityARNavigation() async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch Unity AR app: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class DynamicNavigationPainter extends CustomPainter {
  final double bearing;
  final double distance;
  final String buildingName;
  final double arrowRotation;

  DynamicNavigationPainter({
    required this.bearing,
    required this.distance,
    required this.buildingName,
    required this.arrowRotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final arrowFillPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Calculate center of screen
    final center = Offset(size.width / 2, size.height / 2);

    // Draw dynamic direction arrow that rotates smoothly
    final arrowLength = 120.0;
    final arrowWidth = 30.0;

    // Arrow tip position based on rotation
    final arrowTip = Offset(
      center.dx + arrowLength * sin(arrowRotation),
      center.dy - arrowLength * cos(arrowRotation),
    );

    // Arrow base positions
    final arrowBase1 = Offset(
      arrowTip.dx - arrowWidth * cos(arrowRotation - pi / 6),
      arrowTip.dy - arrowWidth * sin(arrowRotation - pi / 6),
    );

    final arrowBase2 = Offset(
      arrowTip.dx - arrowWidth * cos(arrowRotation + pi / 6),
      arrowTip.dy - arrowWidth * sin(arrowRotation + pi / 6),
    );

    // Draw arrow body
    canvas.drawLine(center, arrowTip, paint);

    // Draw arrow head
    final arrowHead = Path();
    arrowHead.moveTo(arrowTip.dx, arrowTip.dy);
    arrowHead.lineTo(arrowBase1.dx, arrowBase1.dy);
    arrowHead.lineTo(arrowBase2.dx, arrowBase2.dy);
    arrowHead.close();

    canvas.drawPath(arrowHead, arrowFillPaint);
    canvas.drawPath(arrowHead, paint);

    // Draw pulsing circle around arrow base
    final pulsePaint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 15, pulsePaint);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Draw distance text with background
    final textSpan = TextSpan(
      text: '${distance.toStringAsFixed(1)}m to $buildingName',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + 150),
    );

    // Draw compass indicator
    final compassText = TextSpan(
      text: '${(arrowRotation * 180 / pi).toStringAsFixed(0)}°',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    final compassPainter = TextPainter(
      text: compassText,
      textDirection: TextDirection.ltr,
    );

    compassPainter.layout();
    compassPainter.paint(
      canvas,
      Offset(center.dx - compassPainter.width / 2, center.dy - 150),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
