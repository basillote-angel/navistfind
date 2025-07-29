import 'package:navistfind/features/auth/data/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider<AuthService>((ref) => AuthService());
final loginStateProvider = StateProvider<bool>((ref) => false);
final registerStateProvider = StateProvider<bool>((ref) => false);
final logoutStateProvider = StateProvider<bool>((ref) => false);
