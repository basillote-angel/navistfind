import 'package:flutter/material.dart';
import '../data/ar_navigation_launcher_service.dart';

class ARNavigationLauncherWidget extends StatefulWidget {
  final String? buildingName;
  final VoidCallback? onARNotSupported;
  final VoidCallback? onARModuleNotInstalled;

  const ARNavigationLauncherWidget({
    super.key,
    this.buildingName,
    this.onARNotSupported,
    this.onARModuleNotInstalled,
  });

  @override
  State<ARNavigationLauncherWidget> createState() =>
      _ARNavigationLauncherWidgetState();
}

class _ARNavigationLauncherWidgetState
    extends State<ARNavigationLauncherWidget> {
  bool _isUnityAppInstalled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUnityAppInstallation();
  }

  Future<void> _checkUnityAppInstallation() async {
    try {
      final isInstalled =
          await ARNavigationLauncherService.isUnityAppInstalled();
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = isInstalled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if Unity app is not installed
    if (!_isUnityAppInstalled) {
      return const SizedBox.shrink();
    }

    // Show loading indicator while checking
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: () => _launchARNavigation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C2A40),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        icon: const Icon(Icons.view_in_ar, size: 24, color: Colors.white),
        label: Text(
          widget.buildingName != null
              ? 'AR Navigation to ${widget.buildingName}'
              : 'Start AR Navigation',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _launchARNavigation(BuildContext context) async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      // Handle any errors that might occur during launch
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch AR Navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// A floating action button variant for AR navigation
class ARNavigationFAB extends StatefulWidget {
  final String? buildingName;
  final VoidCallback? onARNotSupported;
  final VoidCallback? onARModuleNotInstalled;

  const ARNavigationFAB({
    super.key,
    this.buildingName,
    this.onARNotSupported,
    this.onARModuleNotInstalled,
  });

  @override
  State<ARNavigationFAB> createState() => _ARNavigationFABState();
}

class _ARNavigationFABState extends State<ARNavigationFAB> {
  bool _isUnityAppInstalled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUnityAppInstallation();
  }

  Future<void> _checkUnityAppInstallation() async {
    try {
      final isInstalled =
          await ARNavigationLauncherService.isUnityAppInstalled();
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = isInstalled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if Unity app is not installed
    if (!_isUnityAppInstalled) {
      return const SizedBox.shrink();
    }

    // Show loading indicator while checking
    if (_isLoading) {
      return const FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return FloatingActionButton.extended(
      onPressed: () => _launchARNavigation(context),
      backgroundColor: const Color(0xFF1C2A40),
      foregroundColor: Colors.white,
      icon: const Icon(Icons.view_in_ar),
      label: Text(
        widget.buildingName != null
            ? 'AR to ${widget.buildingName}'
            : 'AR Navigation',
      ),
      elevation: 6,
    );
  }

  Future<void> _launchARNavigation(BuildContext context) async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      // Handle any errors that might occur during launch
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch AR Navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// A card widget for AR navigation with additional information
class ARNavigationCard extends StatefulWidget {
  final String? buildingName;
  final String? description;
  final VoidCallback? onARNotSupported;
  final VoidCallback? onARModuleNotInstalled;

  const ARNavigationCard({
    super.key,
    this.buildingName,
    this.description,
    this.onARNotSupported,
    this.onARModuleNotInstalled,
  });

  @override
  State<ARNavigationCard> createState() => _ARNavigationCardState();
}

class _ARNavigationCardState extends State<ARNavigationCard> {
  bool _isUnityAppInstalled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUnityAppInstallation();
  }

  Future<void> _checkUnityAppInstallation() async {
    try {
      final isInstalled =
          await ARNavigationLauncherService.isUnityAppInstalled();
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = isInstalled;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnityAppInstalled = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show anything if Unity app is not installed
    if (!_isUnityAppInstalled) {
      return const SizedBox.shrink();
    }

    // Show loading indicator while checking
    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.view_in_ar, size: 48, color: Color(0xFF1C2A40)),
            const SizedBox(height: 16),
            Text(
              widget.buildingName != null
                  ? 'AR Navigation to ${widget.buildingName}'
                  : 'AR Navigation',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2A40),
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchARNavigation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C2A40),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Start AR Navigation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchARNavigation(BuildContext context) async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
      // Handle any errors that might occur during launch
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch AR Navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
