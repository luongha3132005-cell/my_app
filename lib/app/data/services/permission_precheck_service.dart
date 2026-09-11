import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thông tin cấu hình quyền cần xin trước khi chẩn đoán
class PermissionInfo {
  final Permission permission;
  final IconData icon;
  final String name;
  final String description;
  final bool required;

  const PermissionInfo({
    required this.permission,
    required this.icon,
    required this.name,
    required this.description,
    this.required = false,
  });
}

/// Service kiểm tra và tiền cấp quyền (Permissions) cho các tính năng chẩn đoán
class PermissionPrecheckService {
  PermissionPrecheckService._();

  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Danh sách các quyền cần kiểm tra trước khi thực hiện chẩn đoán
  static const List<PermissionInfo> diagnosticPermissions = [
    // Dòng 73-78: Khai báo quyền Permission.location trong danh sách quyền kiểm tra trước
    PermissionInfo(
      permission: Permission.location,
      icon: Icons.location_on,
      name: 'Vị trí',
      description: 'Kiểm tra GPS và đọc SSID WiFi',
      required: false,
    ),
    PermissionInfo(
      permission: Permission.bluetoothScan,
      icon: Icons.bluetooth,
      name: 'Bluetooth',
      description: 'Quét và kiểm tra thiết bị Bluetooth xung quanh',
      required: false,
    ),
  ];

  // ==================== WI-FI / LOCATION PERMISSIONS ====================

  /// Kiểm tra trạng thái quyền vị trí phục vụ đọc tên Wi-Fi (SSID)
  static Future<bool> checkWifiPermission() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking Wi-Fi location permission: $e');
      return false;
    }
  }

  /// Yêu cầu cấp quyền vị trí để hệ điều hành cho phép đọc tên Wi-Fi (SSID)
  /// Cả Android 8+ và iOS 13+ đều yêu cầu quyền Location để truy xuất SSID
  static Future<bool> requestWifiPermission() async {
    try {
      // Dòng 73-79: Xin quyền Permission.locationWhenInUse
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) return true;

      if (status.isDenied) {
        debugPrint('Location permission for Wi-Fi SSID denied');
      } else if (status.isPermanentlyDenied) {
        debugPrint('Location permission permanently denied');
      }
      return false;
    } catch (e) {
      debugPrint('Error requesting Wi-Fi location permission: $e');
      return false;
    }
  }

  // ==================== BLUETOOTH PERMISSIONS ====================

  /// Kiểm tra trạng thái cấp quyền Bluetooth hiện tại
  static Future<bool> checkBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 31) {
          // Android 12+ yêu cầu cả bluetoothScan và bluetoothConnect
          final scanStatus = await Permission.bluetoothScan.status;
          final connectStatus = await Permission.bluetoothConnect.status;
          return scanStatus.isGranted && connectStatus.isGranted;
        } else {
          // Android <= 11
          final bluetoothStatus = await Permission.bluetooth.status;
          return bluetoothStatus.isGranted;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.status;
        return status.isGranted;
      }
      return true;
    } catch (e) {
      debugPrint('Error checking Bluetooth permission: $e');
      return false;
    }
  }

  /// Yêu cầu cấp quyền Bluetooth theo từng nền tảng
  static Future<bool> requestBluetoothPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        // Dòng 90-104: Trên Android xin quyền Permission.bluetoothScan và Permission.bluetoothConnect
        if (sdkInt >= 31) {
          final statuses = await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect,
          ].request();

          final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
          final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;

          return scanGranted && connectGranted;
        } else {
          final status = await Permission.bluetooth.request();
          return status.isGranted;
        }
      } else if (Platform.isIOS) {
        // Dòng 107-115: Trên iOS xin quyền Permission.bluetooth
        final status = await Permission.bluetooth.request();
        return status.isGranted;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting Bluetooth permission: $e');
      return false;
    }
  }

  // ==================== COMBINED PRECHECK ====================

  /// Tiền kiểm tra và xin tất cả các quyền cần thiết cho quy trình chẩn đoán
  static Future<Map<String, bool>> precheckAllPermissions() async {
    final wifiGranted = await requestWifiPermission();
    final bluetoothGranted = await requestBluetoothPermission();

    return {
      'wifi_location': wifiGranted,
      'bluetooth': bluetoothGranted,
    };
  }
}
