import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'ar_navigation_launcher_widget.dart';

class ARNavigationExampleScreen extends StatelessWidget {
  const ARNavigationExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR Navigation Examples'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AR Navigation Launcher Examples',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C2A40),
              ),
            ),
            const SizedBox(height: 20),

            // Basic AR Navigation Button
            const Text(
              '1. Basic AR Navigation Button',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2A40),
              ),
            ),
            const SizedBox(height: 8),
            ARNavigationLauncherWidget(),
            const SizedBox(height: 20),

            // AR Navigation Button with Building Name
            const Text(
              '2. AR Navigation to Specific Building',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2A40),
              ),
            ),
            const SizedBox(height: 8),
            ARNavigationLauncherWidget(buildingName: 'Library'),
            const SizedBox(height: 20),

            // AR Navigation Card
            const Text(
              '3. AR Navigation Card',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2A40),
              ),
            ),
            const SizedBox(height: 8),
            ARNavigationCard(
              buildingName: 'Science Building',
              description:
                  'Navigate to the Science Building using AR technology for an immersive experience.',
            ),
            const SizedBox(height: 20),

            // Custom AR Navigation Button
            const Text(
              '4. Custom AR Navigation Button',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C2A40),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _launchCustomARNavigation(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.explore),
                label: const Text(
                  'Explore with AR',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Information Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How it works:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Checks if your device supports ARCore\n'
                    '• Verifies if the Unity AR app is installed\n'
                    '• Launches the AR app if available\n'
                    '• Provides installation options if needed',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ARNavigationFAB(buildingName: 'Campus'),
    );
  }

  Future<void> _launchCustomARNavigation(BuildContext context) async {
    try {
      // You can customize the AR navigation launch here
      // For example, pass specific parameters or handle custom logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Custom AR Navigation launched!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to launch custom AR Navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
