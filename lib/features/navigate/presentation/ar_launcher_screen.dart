import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../data/ar_navigation_launcher_service.dart';

class ARLauncherScreen extends StatefulWidget {
  const ARLauncherScreen({super.key});

  @override
  State<ARLauncherScreen> createState() => _ARLauncherScreenState();
}

class _ARLauncherScreenState extends State<ARLauncherScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isUnityAppInstalled = false;
  bool _isLaunching = false;

  // Animation controllers
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkUnityAppInstalled();
  }

  void _initAnimations() {
    // Rotation animation for 3D effect
    _rotationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    // Float animation (up and down)
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse animation for the button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkUnityAppInstalled() async {
    setState(() => _isLoading = true);
    try {
      final isInstalled =
          await ARNavigationLauncherService.isUnityAppInstalled();
      if (mounted) {
        setState(() {
          // Always show installed view - let the launch handle errors
          // Detection can be unreliable on some devices
          _isUnityAppInstalled = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Still show installed view even if check fails
          _isUnityAppInstalled = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchUnityApp() async {
    setState(() => _isLaunching = true);
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open AR Navigation: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLaunching = false);
      }
    }
  }

  Future<void> _openPlayStore() async {
    final url = Uri.parse(ARNavigationLauncherService.unityAppPlayStoreUrl);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Play Store'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening Play Store: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'AR Navigation',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _checkUnityAppInstalled,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isUnityAppInstalled
              ? _buildInstalledView()
              : _buildNotInstalledView(),
    );
  }

  Widget _buildInstalledView() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 3D Animated AR Visualization
                  _build3DARVisualization(),
                  const SizedBox(height: 40),
                  // Title
                  const Text(
                    'AR Navigation Ready',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2A40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  Text(
                    'Experience campus navigation in\nAugmented Reality',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Animated Launch Button
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton.icon(
                        onPressed: _isLaunching ? null : _launchUnityApp,
                        icon: _isLaunching
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.play_arrow_rounded, size: 28),
                        label: Text(
                          _isLaunching ? 'Opening...' : 'Start AR Navigation',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Info note at bottom
        _buildInfoNoteInstalled(),
      ],
    );
  }

  Widget _buildNotInstalledView() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 3D Animated AR Visualization (greyed out)
                  _build3DARVisualizationDisabled(),
                  const SizedBox(height: 32),
                  // Title
                  const Text(
                    'AR Navigation',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1C2A40),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    'Download the NavistFind AR app to experience augmented reality campus navigation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Download Button (Blue)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _openPlayStore,
                      icon: const Icon(Icons.download_rounded, size: 24),
                      label: const Text(
                        'Download from Play Store',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Try to open anyway button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLaunching ? null : _launchUnityApp,
                      icon: _isLaunching
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.primaryBlue,
                              ),
                            )
                          : Icon(Icons.open_in_new_rounded, size: 20),
                      label: Text(
                        _isLaunching ? 'Opening...' : 'Already installed? Try to open',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryBlue,
                        side: BorderSide(color: AppTheme.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Refresh detection hint
                  TextButton.icon(
                    onPressed: _checkUnityAppInstalled,
                    icon: Icon(
                      Icons.refresh,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    label: Text(
                      'Refresh detection',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Info note at bottom
        _buildInfoNoteNotInstalled(),
      ],
    );
  }

  Widget _build3DARVisualization() {
    return AnimatedBuilder(
      animation: Listenable.merge([_rotationController, _floatAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing circle
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.15),
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Rotating orbit ring 1
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(_rotationController.value * 2 * math.pi)
                    ..rotateX(math.pi / 6),
                  child: Container(
                    width: 170,
                    height: 170,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.25),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Rotating orbit ring 2 (opposite direction)
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateZ(-_rotationController.value * 2 * math.pi)
                    ..rotateY(math.pi / 4),
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryBlue.withOpacity(0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                // Inner glow effect
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryBlue.withOpacity(0.15),
                        AppTheme.primaryBlue.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Center container with 3D rotating arrow
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateY(math.sin(_rotationController.value * 2 * math.pi) * 0.3),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryBlue,
                          AppTheme.primaryBlue.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.navigation_rounded,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Orbiting location dots
                ..._buildOrbitingDots(),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildOrbitingDots() {
    return List.generate(4, (index) {
      final angle = (_rotationController.value * 2 * math.pi) + (index * math.pi / 2);
      final radius = 85.0;
      return Positioned(
        left: 110 + radius * math.cos(angle) - 8,
        top: 110 + radius * math.sin(angle) - 8,
        child: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            _getOrbitIcon(index),
            size: 10,
            color: AppTheme.primaryBlue,
          ),
        ),
      );
    });
  }

  IconData _getOrbitIcon(int index) {
    switch (index) {
      case 0:
        return Icons.place;
      case 1:
        return Icons.location_on;
      case 2:
        return Icons.my_location;
      default:
        return Icons.near_me;
    }
  }

  Widget _build3DARVisualizationDisabled() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value * 0.5),
          child: SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring (static, greyed)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                // Middle ring
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 2,
                    ),
                  ),
                ),
                // Inner glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.grey.shade200,
                        Colors.grey.shade100,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Center icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.navigation_rounded,
                    size: 50,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoNoteInstalled() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Point your camera at buildings to see AR navigation guides.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoNoteNotInstalled() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        border: Border(
          top: BorderSide(color: Colors.amber.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.amber.shade700,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This AR navigation feature uses AR technology. Some devices may not support AR. Please install the Unity AR app to use it.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.amber.shade800,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
