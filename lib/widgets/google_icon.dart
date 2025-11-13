import 'package:flutter/material.dart';

/// Google icon widget using the official Google logo image
class GoogleIcon extends StatelessWidget {
  final double size;

  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
