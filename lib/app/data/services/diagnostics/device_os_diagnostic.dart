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
      if (Platform.isAndroid) {
        final a = await _deviceInfo.androidInfo;
        final vendor = a.manufacturer.toLowerCase();
        final marketingName = DeviceNameMapper.getMarketingName(
          a.model,
          a.brand,
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
          'ram': ramInfo,
          'rom': romInfo,
        };

        debugPrint('Android Device Info: $data');
        return data;
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        final machine = i.utsname.machine;
        final friendlyName = await DeviceInfoHelper.getModel();

        final data = {
          'platform': 'ios',
          'systemVersion': i.systemVersion,
          'model': machine,
          'marketingName': friendlyName,
          'name': i.name,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'vendor': 'apple',
          'isSamsung': false,
          'isApple': true,
        };

        debugPrint('iOS Device Info: $data');
        return data;
      }

      return {'platform': 'unknown', 'origin': 'Không xác định'};
    } catch (e) {
      debugPrint('Error in DeviceOsDiagnostic: $e');
      return {'platform': 'error', 'error': e.toString()};
    }
  }
}
