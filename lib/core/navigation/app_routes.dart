import 'package:navistfind/core/navigation/navigation_wrapper.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:navistfind/features/auth/presentation/login_screen.dart';
import 'package:navistfind/features/auth/presentation/register_screen.dart';
import 'package:navistfind/features/auth/presentation/splash_screen.dart';
import 'package:navistfind/features/auth/presentation/forgot_password_screen.dart';
import 'package:navistfind/features/home/presentation/recommendations_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const recommendations = '/recommendations';
  static const checkAuth = '/';
  static const splash = '/splash';

  static final routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    forgotPassword: (context) => const ForgotPasswordScreen(),
    home: (context) => const NavigationWrapper(),
    recommendations: (context) => const RecommendationsScreen(),
    checkAuth: (context) => FutureBuilder(
      future: SecureStorage.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshot.hasData) {
          return const NavigationWrapper();
        } else {
          return const LoginScreen();
        }
      },
    ),
  };
}
