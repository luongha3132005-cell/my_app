import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Chuyên trách kiểm tra trạng thái dịch vụ định vị GPS, xin quyền và đo sai số mét
class GpsDiagnostic {
  const GpsDiagnostic();

  /// Thực hiện kiểm tra dịch vụ vị trí, xin quyền và lấy độ chính xác (accuracy)
  Future<Map<String, dynamic>> checkGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final svc = await Geolocator.isLocationServiceEnabled();

      double? accuracy;
      if (svc && (perm == LocationPermission.always || perm == LocationPermission.whileInUse)) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 5),
            ),
          );
          accuracy = pos.accuracy;
        } catch (_) {}
      }

      final data = {
        'serviceOn': svc,
        'accuracyM': accuracy,
        'permission': perm.name,
      };

      debugPrint('GPS Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in GpsDiagnostic: $e');
      return {
        'serviceOn': false,
        'accuracyM': null,
        'error': e.toString(),
      };
    }
  }
}
