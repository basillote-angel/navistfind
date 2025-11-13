import 'dart:io';
import 'package:navistfind/core/network/api_client.dart';

class DeviceTokenService {
  Future<void> registerToken(String token) async {
    final platform = Platform.isAndroid
        ? 'android'
        : (Platform.isIOS ? 'ios' : 'web');
    await ApiClient.client.post(
      '/api/device-tokens',
      data: {'platform': platform, 'token': token},
    );
  }

  Future<void> deleteToken(String token) async {
    await ApiClient.client.delete('/api/device-tokens', data: {'token': token});
  }
}
