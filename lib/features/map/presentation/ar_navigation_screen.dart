import 'package:flutter/material.dart';

class ARNavigationScreen extends StatefulWidget {
  final String buildingName;

  const ARNavigationScreen({super.key, required this.buildingName});

  @override
  State<ARNavigationScreen> createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Navigation to ${widget.buildingName}'),
        backgroundColor: const Color(0xFF1C2A40),
      ),
      body: const Center(
        child: Text(
          'AR Navigation would appear here.\n(Unity integration not yet implemented)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
