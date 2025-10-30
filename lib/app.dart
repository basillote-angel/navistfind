import 'package:navistfind/core/navigation/app_routes.dart';
import 'package:navistfind/core/theme/app_theme.dart';
import 'package:navistfind/widgets/performance_monitor.dart';
import 'package:flutter/material.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Modular Flutter App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF123A7D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123A7D),
          primary: const Color(0xFF123A7D),
          secondary: const Color(0xFF123A7D),
          background: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Color(0xFF123A7D),
          backgroundColor: Color(0xFF123A7D),
        ),
      ),
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
      builder: (context, child) => PerformanceMonitor(
        enabled: false,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
