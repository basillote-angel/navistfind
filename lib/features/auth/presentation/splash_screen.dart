import 'dart:async';
import 'package:flutter/material.dart';
import 'package:navistfind/core/navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeLogo;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(curve);

    _controller.forward();
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.checkAuth);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoSize = width * 0.9;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeLogo,
            child: SizedBox(
              width: logoSize,
              height: logoSize,
              child: Image.asset(
                'assets/images/navistfind_logo.png',
                fit: BoxFit.contain
              ),
            ),
          ),
        ),
      ),
    );
  }
}
