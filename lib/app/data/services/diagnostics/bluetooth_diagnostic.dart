import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../permission_precheck_service.dart';
import '../profile_manager.dart';

/// Chuyên trách kiểm tra trạng thái adapter Bluetooth, xin quyền và quét thiết bị xung quanh
class BluetoothDiagnostic {
  const BluetoothDiagnostic();

  /// Thực hiện xin quyền, kiểm tra adapter và quét thiết bị trong 2 giây
  Future<Map<String, dynamic>> checkBluetooth({required String brand}) async {
    try {
      // 1. Tiền kiểm tra và yêu cầu cấp quyền Bluetooth theo từng nền tảng
      final hasPermission = await PermissionPrecheckService.requestBluetoothPermission();

      // 2. Dùng flutter_blue_plus kiểm tra adapter Bluetooth có đang Bật không
      bool isEnabled = false;
      try {
        isEnabled = await FlutterBluePlus.adapterState.first.then(
          (s) => s == BluetoothAdapterState.on,
        ).timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on,
        );
      } catch (_) {
        isEnabled = FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on;
      }

      if (!isEnabled) {
        return {
          'enabled': false,
          'scanOk': false,
          'hasScanPermission': hasPermission,
          'devicesCount': 0,
        };
      }

      // 3. Chạy quét thực tế trong 2 giây
      bool scanOk = false;
      int devicesCount = 0;

      if (hasPermission && isEnabled) {
        try {
          final subscription = FlutterBluePlus.scanResults.listen((results) {
            devicesCount = results.length;
          });

          await FlutterBluePlus.startScan(timeout: const Duration(seconds: 2));
          await Future.delayed(const Duration(seconds: 2));
          await FlutterBluePlus.stopScan();
          await subscription.cancel();
          scanOk = true;
        } catch (e) {
          debugPrint('Error during Bluetooth scan: $e');
          scanOk = false;
        }
      }

      final isMiui = ProfileManager.isMiuiOrXiaomi(brand);

      final data = {
        'enabled': isEnabled,
        'scanOk': scanOk,
        'hasScanPermission': hasPermission,
        'devicesCount': devicesCount,
        'isMiui': isMiui,
      };

      debugPrint('Bluetooth Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in BluetoothDiagnostic: $e');
      return {
        'enabled': false,
        'scanOk': false,
        'hasScanPermission': false,
        'devicesCount': 0,
        'error': e.toString(),
      };
    }
  }
}
