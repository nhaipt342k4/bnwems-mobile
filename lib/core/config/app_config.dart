import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'BNWEMS Staff';

  /// Base URL mặc định kết nối Backend (Backend chạy ở PORT 3001 theo .env)
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.tochucsukien-binhnguyen.space/api/v1',
  );

  /// Base URL cho API backend.
  /// Tự động chuyển đổi `localhost` sang `10.0.2.2` khi chạy trên Android Emulator.
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid && _envBaseUrl.contains('localhost')) {
      return _envBaseUrl.replaceAll('localhost', '10.0.2.2');
    }
    return _envBaseUrl;
  }

  /// Key lưu trữ Bearer token đăng nhập
  static const String authTokenKey = 'bnwems_staff_auth_token';

  /// Key lưu trữ thông tin User dạng JSON
  static const String authUserKey = 'bnwems_staff_auth_user';

  /// Bán kính GPS Geofence cho điểm danh hiện trường (200m theo SRS UC-103)
  static const double geofenceRadiusMeters = 200.0;
}
