import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  CameraController? controller;
  bool _initializing = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() {
          _error = 'No camera available';
          _initializing = false;
        });
        return;
      }
      final cam = cams.first;
      final ctrl = CameraController(cam, ResolutionPreset.max);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() {
        controller = ctrl;
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _initializing = false;
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null ||
        controller == null ||
        !controller!.value.isInitialized) {
      return Scaffold(
        body: Center(child: Text(_error ?? 'Failed to initialize camera')),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(controller!)),

          // Floating back button
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
