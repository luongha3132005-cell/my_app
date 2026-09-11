import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../profile_manager.dart';

/// Chuyên trách kiểm tra trạng thái kết nối Wi-Fi, xin quyền vị trí và đọc tên mạng (SSID)
class WifiDiagnostic {
  final MethodChannel methodChannel;
  final Connectivity connectivity;
  final NetworkInfo networkInfo;

  WifiDiagnostic({
    MethodChannel? methodChannel,
    Connectivity? connectivity,
    NetworkInfo? networkInfo,
  })  : methodChannel = methodChannel ?? const MethodChannel('com.fidobox/diagnostics'),
        connectivity = connectivity ?? Connectivity(),
        networkInfo = networkInfo ?? NetworkInfo();

  /// Thực hiện kiểm tra Wi-Fi và đọc SSID
  Future<Map<String, dynamic>> checkWifi({required String brand}) async {
    try {
      // 1. Kiểm tra trạng thái phần cứng chip Wi-Fi có bật hay không
      bool isEnabled = false;
      if (Platform.isAndroid) {
        try {
          isEnabled = await methodChannel.invokeMethod<bool>('isWifiEnabled') ?? false;
        } catch (_) {
          isEnabled = true; // Fallback
        }
      } else {
        isEnabled = true; // Fallback trên iOS
      }

      // 2. Dùng connectivity_plus kiểm tra có đang kết nối mạng Wi-Fi không
      final connectivityResult = await connectivity.checkConnectivity();
      final isConnected = connectivityResult.contains(ConnectivityResult.wifi);

      if (isConnected) {
        isEnabled = true;
      }

      // 3. Xin quyền Location runtime để đọc được SSID (Android 8+ & iOS 13+ bắt buộc)
      String? ssid;
      bool hasLocation = await Permission.locationWhenInUse.isGranted;
      if (!hasLocation) {
        final reqStatus = await Permission.locationWhenInUse.request();
        hasLocation = reqStatus.isGranted;
      }

      // Đọc SSID qua NetworkInfo().getWifiName()
      if (isConnected) {
        try {
          final rawSsid = await networkInfo.getWifiName();
          if (rawSsid != null) {
            ssid = rawSsid.replaceAll('"', '').trim();
          }
        } catch (e) {
          debugPrint('Error getting Wi-Fi SSID: $e');
        }
      }

      final data = {
        'enabled': isEnabled,
        'connected': isConnected,
        'ssid': ssid,
        'hasLocationPermission': hasLocation,
        'requiresLocationStrict': ProfileManager.requiresLocationForWifi(brand),
      };

      debugPrint('Wi-Fi Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in WifiDiagnostic: $e');
      return {
        'enabled': false,
        'connected': false,
        'ssid': null,
        'error': e.toString(),
      };
    }
  }
}
