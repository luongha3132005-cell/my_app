import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../device_info_helper.dart';
import '../device_name_mapper.dart';

/// Chuyên trách thu thập thông tin Hệ điều hành, Nhà sản xuất, Model và Tên thương mại
class DeviceOsDiagnostic {
  final DeviceInfoPlugin _deviceInfo;

  DeviceOsDiagnostic({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Lấy thông tin OS, Brand, Model kỹ thuật và Tên thương mại
  Future<Map<String, dynamic>> getOsAndModel({
    Map<String, dynamic>? ramInfo,
    Map<String, dynamic>? romInfo,
  }) async {
    try {
      final deviceIdInfo = await DeviceInfoHelper.getDeviceIdInfo();

      if (Platform.isAndroid) {
        final a = await _deviceInfo.androidInfo;
        final vendor = a.manufacturer.toLowerCase();
        final marketingName = DeviceNameMapper.getMarketingName(
          a.model,
          a.brand,
          a.manufacturer,
        );

        final itCode = buildItCode(
          model: a.model,
          ramInfo: ramInfo,
          romInfo: romInfo,
        );

        final data = {
          'platform': 'android',
          'sdk': a.version.sdkInt,
          'release': a.version.release,
          'model': a.model,
          'brand': a.brand,
          'manufacturer': a.manufacturer,
          'vendor': vendor,
          'marketingName': marketingName,
          'IT_Code': itCode,
          'deviceId': deviceIdInfo['deviceId'], // Build ID (ví dụ: SP1A.210812.016)
          'androidId': deviceIdInfo['androidId'], // ANDROID_ID duy nhất (ví dụ: a83d4c2dc16f3a8e)
          'hardwareDevice': deviceIdInfo['hardwareDevice'], // Mã bo mạch (ví dụ: d2s)
          'fingerprint': deviceIdInfo['fingerprint'],
          'ram': ramInfo,
          'rom': romInfo,
        };

        _logDeviceInfo(
          marketingName: marketingName,
          model: '${a.model} (${a.brand})',
          itCode: itCode,
          deviceId: deviceIdInfo['deviceId'],
          extraLines: [
            '🆔 Android ID (Định danh duy nhất): ${deviceIdInfo['androidId']}',
            '⚙️ Hardware Codename: ${deviceIdInfo['hardwareDevice']}',
            '🏷️ OS Release: Android ${a.version.release} (SDK ${a.version.sdkInt})',
          ],
        );

        return data;
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        final machine = i.utsname.machine;
        final friendlyName = await DeviceInfoHelper.getModel();

        final itCode = buildItCode(
          model: machine,
          ramInfo: ramInfo,
          romInfo: romInfo,
        );

        final data = {
          'platform': 'ios',
          'systemVersion': i.systemVersion,
          'model': machine,
          'marketingName': friendlyName,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'vendor': 'apple',
          'IT_Code': itCode,
          'deviceId': deviceIdInfo['deviceId'],
          'ram': ramInfo,
          'rom': romInfo,
        };

        _logDeviceInfo(
          marketingName: friendlyName,
          model: machine,
          itCode: itCode,
          deviceId: deviceIdInfo['deviceId'],
          extraLines: [
            '🏷️ iOS Version: ${i.systemVersion}',
          ],
        );

        return data;
      }

      return {'platform': 'unknown'};
    } catch (e) {
      debugPrint('Error in DeviceOsDiagnostic: $e');
      return {'platform': 'error', 'error': e.toString()};
    }
  }

  /// Ghi log thông số thiết bị ra console đồng bộ
  void _logDeviceInfo({
    required String marketingName,
    required String model,
    required String itCode,
    dynamic deviceId,
    List<String> extraLines = const [],
  }) {
    debugPrint('==================== [DEVICE ID & HARDWARE INFO] ====================');
    debugPrint('📱 Marketing Name: $marketingName');
    debugPrint('🔧 Model Kỹ Thuật: $model');
    debugPrint('🏷️ IT_Code (modelcode_ram_rom): $itCode');
    debugPrint('🔑 Device ID: $deviceId');
    for (final line in extraLines) {
      debugPrint(line);
    }
    debugPrint('=====================================================================');
  }

  /// Hàm tạo mã IT_Code chuẩn kết hợp từ model, ram và rom
  static String buildItCode({
    required String model,
    Map<String, dynamic>? ramInfo,
    Map<String, dynamic>? romInfo,
  }) {
    String ramStr = '';
    if (ramInfo != null) {
      if (ramInfo['totalGB'] != null) {
        ramStr = '${ramInfo['totalGB']}GB';
      } else if (ramInfo['totalBytes'] is num && ramInfo['totalBytes'] > 0) {
        final gb = (ramInfo['totalBytes'] as num) / (1024 * 1024 * 1024);
        int matched;
        if (gb > 18) {
          matched = 24;
        } else if (gb > 13) {
          matched = 16;
        } else if (gb > 9) {
          matched = 12;
        } else if (gb > 6.5) {
          matched = 8;
        } else if (gb > 4.5) {
          matched = 6;
        } else if (gb > 3.2) {
          matched = 4;
        } else if (gb > 2.2) {
          matched = 3;
        } else if (gb > 1.2) {
          matched = 2;
        } else {
          matched = gb.round();
        }
        ramStr = '${matched}GB';
      }
    }

    String romStr = '';
    if (romInfo != null) {
      if (romInfo['totalBytes'] is num && romInfo['totalBytes'] > 0) {
        final gb = (romInfo['totalBytes'] as num) / (1024 * 1024 * 1024);
        int matched;
        if (gb > 700) {
          matched = 1024;
        } else if (gb > 350) {
          matched = 512;
        } else if (gb > 160) {
          matched = 256;
        } else if (gb > 75) {
          matched = 128;
        } else if (gb > 36) {
          matched = 64;
        } else if (gb > 18) {
          matched = 32;
        } else if (gb > 9) {
          matched = 16;
        } else {
          matched = gb.round();
        }
        romStr = '${matched}GB';
      } else if (romInfo['totalGB'] != null) {
        romStr = '${romInfo['totalGB']}GB';
      }
    }

    final cleanModel = model.trim().replaceAll(' ', '_');
    final parts = [
      cleanModel,
      ramStr.isNotEmpty ? ramStr : '0GB',
      romStr.isNotEmpty ? romStr : '0GB',
    ];
    return parts.join('_');
  }
}