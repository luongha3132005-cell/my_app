import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

const _channel = MethodChannel('com.fidobox/diagnostics');

/// Helper class hỗ trợ lấy thông tin phần cứng thiết bị đa nền tảng
class DeviceInfoHelper {
  DeviceInfoHelper._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // ==================== RAM INFO ====================

  /// Lấy thông tin RAM
  /// - Android: Sử dụng MethodChannel gọi native xuống ActivityManager
  /// - iOS: Ước tính dựa trên model hardware identifier
  static Future<Map<String, dynamic>> getRamInfo() async {
    if (Platform.isAndroid) {
      return _getAndroidRamInfo();
    } else if (Platform.isIOS) {
      return _getIosRamInfo();
    }
    return const {'freeBytes': null, 'totalBytes': null, 'source': 'unknown'};
  }

  static Future<Map<String, dynamic>> _getAndroidRamInfo() async {
    try {
      final Map? raw = await _channel.invokeMethod<Map>('getRamInfo');
      if (raw == null) {
        return const {
          'freeBytes': null,
          'totalBytes': null,
          'source': 'android_null',
        };
      }
      return {
        'freeBytes': raw['freeBytes'] ?? raw['free_bytes'],
        'totalBytes': raw['totalBytes'] ?? raw['total_bytes'],
        'source': 'android_native',
      };
    } catch (e) {
      return {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'android_error',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _getIosRamInfo() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      final ramGB = _estimateIosRam(iosInfo.utsname.machine);
      final totalBytes = (ramGB * 1024 * 1024 * 1024).toInt();

      return {
        'freeBytes': null, // iOS bảo mật không cung cấp API đọc free RAM
        'totalBytes': totalBytes,
        'totalGB': ramGB,
        'source': 'ios_estimated',
        'model': iosInfo.utsname.machine,
      };
    } catch (e) {
      return {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'ios_error',
        'error': e.toString(),
      };
    }
  }

  /// Ước tính dung lượng RAM dựa trên model máy iOS (Apple specs)
  static int _estimateIosRam(String machine) {
    // iPhone
    if (machine.startsWith('iPhone')) {
      final parts = machine.replaceAll('iPhone', '').split(',');
      final major = int.tryParse(parts[0]) ?? 0;

      // iPhone 15 Pro / Pro Max: iPhone16,x -> 8GB
      if (major >= 16) return 8;
      // iPhone 14 Pro / Pro Max: iPhone15,x -> 6GB
      if (major >= 15) return 6;
      // iPhone 13 series: iPhone14,x -> 4-6GB (trung bình 4GB tiêu chuẩn)
      if (major >= 14) return 4;
      // iPhone 12 series: iPhone13,x -> 4GB
      if (major >= 13) return 4;
      // iPhone 11 series: iPhone12,x -> 4GB
      if (major >= 12) return 4;
      // iPhone X/XS: iPhone10,x / 11,x -> 3GB
      if (major >= 10) return 3;
      // iPhone 7/8: iPhone9,x -> 2GB
      if (major >= 9) return 2;
      return 2;
    }

    // iPad
    if (machine.startsWith('iPad')) {
      final parts = machine.replaceAll('iPad', '').split(',');
      final major = int.tryParse(parts[0]) ?? 0;

      // iPad Pro M2+: iPad14,x+ -> 8-16GB
      if (major >= 14) return 8;
      // iPad Air/Pro: iPad13,x -> 8GB
      if (major >= 13) return 8;
      // iPad tiêu chuẩn: iPad12,x -> 4GB
      if (major >= 12) return 4;
      return 4;
    }

    // Mặc định
    return 4;
  }

  // ==================== ROM INFO ====================

  /// Lấy thông tin ROM (Dung lượng bộ nhớ trong)
  /// - Android: Gọi native MethodChannel StatFs
  /// - iOS: Trả về thông tin trạng thái & các mức tiêu chuẩn
  static Future<Map<String, dynamic>> getRomInfo() async {
    if (Platform.isAndroid) {
      return _getAndroidRomInfo();
    } else if (Platform.isIOS) {
      return _getIosRomInfo();
    }
    return const {'freeBytes': null, 'totalBytes': null, 'source': 'unknown'};
  }

  static Future<Map<String, dynamic>> _getAndroidRomInfo() async {
    try {
      final Map? raw = await _channel.invokeMethod<Map>('getRomInfo');
      if (raw == null) {
        return const {
          'freeBytes': null,
          'totalBytes': null,
          'source': 'android_null',
        };
      }
      return {
        'freeBytes': raw['freeBytes'] ?? raw['free_bytes'],
        'totalBytes': raw['totalBytes'] ?? raw['total_bytes'],
        'source': 'android_native',
      };
    } catch (e) {
      return {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'android_error',
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> _getIosRomInfo() async {
    try {
      final iosInfo = await _deviceInfo.iosInfo;
      return {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'ios_unavailable',
        'note': 'iOS không cho phép đọc dung lượng bộ nhớ chính xác từ sandbox',
        'model': iosInfo.utsname.machine,
        'commonCapacities': [64, 128, 256, 512, 1024], // GB
      };
    } catch (e) {
      return {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'ios_error',
        'error': e.toString(),
      };
    }
  }

  // ==================== MODEL & BRAND ====================

  /// Lấy tên thương hiệu / Hãng thiết bị
  static Future<String> getBrand() async {
    if (Platform.isIOS) {
      return 'Apple';
    }

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.brand;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Lấy tên model thiết bị
  static Future<String> getModel() async {
    if (Platform.isIOS) {
      try {
        final iosInfo = await _deviceInfo.iosInfo;
        return _mapIosModelName(iosInfo.utsname.machine);
      } catch (_) {
        return 'iPhone';
      }
    }

    try {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.model;
    } catch (_) {
      return 'Unknown';
    }
  }

  /// Map iOS machine identifier sang tên thương mại thân thiện
  static String _mapIosModelName(String machine) {
    final iphoneMap = {
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,6': 'iPhone SE (3rd gen)',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone13,4': 'iPhone 12 Pro Max',
      'iPhone13,3': 'iPhone 12 Pro',
      'iPhone13,2': 'iPhone 12',
      'iPhone13,1': 'iPhone 12 mini',
      'iPhone12,8': 'iPhone SE (2nd gen)',
      'iPhone12,5': 'iPhone 11 Pro Max',
      'iPhone12,3': 'iPhone 11 Pro',
      'iPhone12,1': 'iPhone 11',
      'iPhone11,8': 'iPhone XR',
      'iPhone11,6': 'iPhone XS Max',
      'iPhone11,4': 'iPhone XS Max',
      'iPhone11,2': 'iPhone XS',
      'iPhone10,6': 'iPhone X',
      'iPhone10,5': 'iPhone 8 Plus',
      'iPhone10,4': 'iPhone 8',
      'iPhone10,3': 'iPhone X',
      'iPhone10,2': 'iPhone 8 Plus',
      'iPhone10,1': 'iPhone 8',
    };

    if (iphoneMap.containsKey(machine)) {
      return iphoneMap[machine]!;
    }

    if (machine.startsWith('iPhone')) {
      return 'iPhone ($machine)';
    }
    if (machine.startsWith('iPad')) {
      return 'iPad ($machine)';
    }

    return machine;
  }

  // ==================== DEVICE ID ====================
  /// Lấy thông tin định danh máy chi tiết (Build ID, Android ID / IDFV, Hardware Device)
  static Future<Map<String, dynamic>> getDeviceIdInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        String androidId = 'unknown';
        try {
          androidId = await _channel.invokeMethod<String>('getAndroidId') ?? 'unknown';
        } catch (_) {}

        return {
          'deviceId': androidInfo.id, // Build ID (ví dụ: SP1A.210812.016)
          'androidId': androidId, // Mã ANDROID_ID định danh duy nhất (ví dụ: a83d4c2dc16f3a8e)
          'hardwareDevice': androidInfo.device, // Mã bo mạch (ví dụ: d2s)
          'fingerprint': androidInfo.fingerprint,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        final idfv = iosInfo.identifierForVendor ?? 'unknown';
        return {
          'deviceId': idfv,
          'identifierForVendor': idfv,
          'hardwareDevice': iosInfo.utsname.machine,
        };
      }
    } catch (_) {}
    return {'deviceId': 'unknown'};
  }

  /// Lấy mã định danh thiết bị duy nhất
  static Future<String> getDeviceId() async {
    final info = await getDeviceIdInfo();
    return (info['androidId'] ?? info['deviceId'] ?? 'unknown').toString();
  }

  // ==================== PLATFORM HELPERS ====================
  static bool get isIOS => Platform.isIOS;
  static bool get isAndroid => Platform.isAndroid;
  static String get platform => Platform.isIOS ? 'ios' : 'android';
}
