import 'package:flutter/material.dart';
import '../data/ar_navigation_launcher_service.dart';

/// A widget that conditionally shows AR navigation options
/// Only displays when the Unity AR app is installed
class ARNavigationConditionalWidget extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final Widget? fallbackWidget;
  final Widget? loadingWidget;

  const ARNavigationConditionalWidget({
    super.key,
    required this.builder,
    this.fallbackWidget,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ARNavigationLauncherService.isUnityAppInstalled(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return builder(context);
        }

        // Don't show anything if Unity app is not installed
        return fallbackWidget ?? const SizedBox.shrink();
      },
    );
  }
}

/// A simple conditional AR button that only shows when Unity app is installed
class ConditionalARButton extends StatelessWidget {
  final String? buildingName;
  final VoidCallback? onPressed;
  final Widget? fallbackWidget;

  const ConditionalARButton({
    super.key,
    this.buildingName,
    this.onPressed,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ARNavigationConditionalWidget(
      builder: (context) => ElevatedButton.icon(
        onPressed: onPressed ?? () => _launchARNavigation(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1C2A40),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.view_in_ar, size: 20),
        label: Text(
          buildingName != null
              ? 'AR Navigation to $buildingName'
              : 'Start AR Navigation',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      fallbackWidget: fallbackWidget,
    );
  }

  Future<void> _launchARNavigation(BuildContext context) async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
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

/// A conditional AR icon button for app bars
class ConditionalARIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? tooltip;
  final IconData? icon;
  final Widget? fallbackWidget;

  const ConditionalARIconButton({
    super.key,
    this.onPressed,
    this.tooltip,
    this.icon,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ARNavigationConditionalWidget(
      builder: (context) => IconButton(
        icon: Icon(icon ?? Icons.view_in_ar),
        onPressed: onPressed ?? () => _launchARNavigation(context),
        tooltip: tooltip ?? 'Launch Unity AR App',
      ),
      fallbackWidget: fallbackWidget,
    );
  }

  Future<void> _launchARNavigation(BuildContext context) async {
    try {
      await ARNavigationLauncherService.launchARNavigation(context);
    } catch (e) {
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
