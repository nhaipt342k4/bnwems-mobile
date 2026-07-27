import 'dart:math';
import '../config/app_config.dart';

class GeofenceResult {
  final bool isWithinRadius;
  final double distanceMeters;

  GeofenceResult({
    required this.isWithinRadius,
    required this.distanceMeters,
  });
}

class GeofenceUtil {
  /// Tính khoảng cách Haversine giữa 2 tọa độ (vĩ độ, kinh độ) tính theo mét.
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusMeters = 6371000.0;
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Kiểm tra xem vị trí hiện tại của thiết bị có nằm trong bán kính (mặc định 200m) của vị trí kế hoạch hay không.
  static GeofenceResult checkGeofence({
    required double currentLat,
    required double currentLon,
    required double targetLat,
    required double targetLon,
    double maxRadiusMeters = AppConfig.geofenceRadiusMeters,
  }) {
    final distance = calculateDistanceMeters(currentLat, currentLon, targetLat, targetLon);
    return GeofenceResult(
      isWithinRadius: distance <= maxRadiusMeters,
      distanceMeters: distance,
    );
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}
