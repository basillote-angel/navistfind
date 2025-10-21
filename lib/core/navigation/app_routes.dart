import 'package:navistfind/core/navigation/navigation_wrapper.dart';
import 'package:navistfind/core/secure_storage.dart';
import 'package:navistfind/features/auth/presentation/login_screen.dart';
import 'package:navistfind/features/auth/presentation/register_screen.dart';
import 'package:navistfind/features/auth/presentation/splash_screen.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const checkAuth = '/';
  static const splash = '/splash';

  static final routes = {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    home: (context) => const NavigationWrapper(),
    register: (context) => const RegisterScreen(),
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
