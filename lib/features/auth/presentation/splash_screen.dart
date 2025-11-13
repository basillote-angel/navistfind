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
  late final AnimationController animationController;
  late final Animation<double> fadeInAnimation;
  late final Animation<double> scaleUpAnimation;
  late final Animation<double> slideUpAnimation;
  Timer? navigationTimer;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    final curve = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOutCubic,
    );
    fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    scaleUpAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(curve);
    slideUpAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(curve);

    animationController.forward();
    navigationTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.checkAuth);
    });
  }

  @override
  void dispose() {
    navigationTimer?.cancel();
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final logoSize = width * 0.38;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, slideUpAnimation.value),
                child: Transform.scale(
                  scale: scaleUpAnimation.value,
                  child: child,
                ),
              );
            },
            child: FadeTransition(
              opacity: fadeInAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: logoSize,
                    height: logoSize,
                    child: Image.asset(
                      'assets/images/navistfind_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'NavistFind',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF123A7D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Campus Navigation & Lost + Found',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animationController,
                      curve: const Interval(0.65, 1.0),
                    ),
                    child: const Text(
                      'Syncing campus data...',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
