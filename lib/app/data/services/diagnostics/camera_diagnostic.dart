import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';
import '../permission_precheck_service.dart';

/// Dịch vụ chẩn đoán phần cứng Camera (Camera trước, Camera sau, Đèn Flash, Lấy nét)
class CameraDiagnostic {
  const CameraDiagnostic();

  /// Kiểm tra nhanh quyền truy cập Camera
  Future<bool> hasPermission() async {
    return await PermissionPrecheckService.checkCameraPermission();
  }

  /// Kích hoạt quy trình kiểm tra Camera hoàn chỉnh:
  /// 1. Xin quyền Camera nếu chưa được cấp
  /// 2. Lấy danh sách camera thiết bị (availableCameras)
  /// 3. Chuyển sang màn hình CameraTestPage và chờ kết quả thẩm định
  Future<Map<String, dynamic>> checkCamera() async {
    try {
      // 1. Kiểm tra và yêu cầu cấp quyền Camera
      final isGranted = await PermissionPrecheckService.requestCameraPermission();
      if (!isGranted) {
        debugPrint('Camera permission denied by user');
        return {
          'permission': false,
          'backCamera': false,
          'frontCamera': false,
          'flash': false,
          'userConfirm': false,
          'error': 'permission_denied',
        };
      }

      // 2. Lấy danh sách camera khả dụng
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No available cameras found on device');
        return {
          'permission': true,
          'noCameras': true,
          'backCamera': false,
          'frontCamera': false,
          'flash': false,
          'userConfirm': false,
          'error': 'no_cameras',
        };
      }

      // 3. Mở màn hình CameraTestPage
      final result = await Get.toNamed(
        AppRoutes.cameraTest,
        arguments: cameras,
      );

      final data = (result is Map<String, dynamic>)
          ? result
          : {
              'permission': true,
              'backCamera': false,
              'frontCamera': false,
              'flash': false,
              'userConfirm': false,
            };

      debugPrint('Camera Diagnostic Result: $data');
      return data;
    } catch (e) {
      debugPrint('Error in CameraDiagnostic: $e');
      return {
        'permission': false,
        'backCamera': false,
        'frontCamera': false,
        'flash': false,
        'userConfirm': false,
        'error': e.toString(),
      };
    }
  }
}
