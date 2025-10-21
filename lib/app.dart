import 'package:navistfind/core/navigation/app_routes.dart';
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
        primaryColor: const Color(0xFF1C2A40),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1C2A40),
          primary: const Color(0xFF1C2A40),
          secondary: const Color(0xFF1C2A40),
          background: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C2A40),
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          indicatorColor: Color(0xFF1C2A40),
          backgroundColor: Color(0xFF1C2A40),
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
