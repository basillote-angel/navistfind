import 'package:flutter/material.dart';
import 'dart:async';

/// A simple performance monitoring widget that shows frame rate and performance metrics
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor>
    with WidgetsBindingObserver {
  Timer? _timer;
  int _frameCount = 0;
  double _fps = 0.0;
  String _performanceStatus = 'Good';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.enabled) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startMonitoring() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _fps = _frameCount.toDouble();
          _frameCount = 0;
          
          // Determine performance status
          if (_fps >= 55) {
            _performanceStatus = 'Excellent';
          } else if (_fps >= 45) {
            _performanceStatus = 'Good';
          } else if (_fps >= 30) {
            _performanceStatus = 'Fair';
          } else {
            _performanceStatus = 'Poor';
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.enabled) {
      _startMonitoring();
    } else if (state == AppLifecycleState.paused) {
      _timer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.enabled)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'FPS: ${_fps.toStringAsFixed(1)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _performanceStatus,
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_performanceStatus) {
      case 'Excellent':
        return Colors.green;
      case 'Good':
        return Colors.lightGreen;
      case 'Fair':
        return Colors.orange;
      case 'Poor':
        return Colors.red;
      default:
        return Colors.white;
    }
  }

  /// Call this method to increment frame count
  void incrementFrameCount() {
    _frameCount++;
  }
}

/// Mixin to add performance monitoring to any widget
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  void monitorPerformance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This will be called after each frame is rendered
      // You can add custom performance monitoring logic here
    });
  }
}
