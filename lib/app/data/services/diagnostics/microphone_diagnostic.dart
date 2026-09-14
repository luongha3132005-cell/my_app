import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../modules/funtion_check/widgets/mic_test_dialog.dart';

/// Chuyên trách kiểm tra tính năng phần cứng Microphone & tương tác thu âm
class MicrophoneDiagnostic {
  const MicrophoneDiagnostic();

  /// Kiểm tra nhanh trạng thái quyền Microphone
  Future<bool> hasPermission() async {
    return (await Permission.microphone.status).isGranted;
  }

  /// Kích hoạt quy trình kiểm tra Microphone tương tác hoàn chỉnh:
  /// 1. Thu âm 5 giây và vẽ sóng âm biên độ thời gian thực
  /// 2. Tự động phát lại file âm thanh vừa ghi
  /// 3. Hộp thoại hỏi người dùng xác nhận có nghe rõ không
  Future<Map<String, dynamic>> checkMicrophone() async {
    try {
      final result = await Get.dialog<Map<String, dynamic>>(
        const MicTestDialog(),
        barrierDismissible: false,
      );

      final data = result ?? {
        'permission': false,
        'recorded': false,
        'hasDetectedSound': false,
        'userConfirm': false,
      };

      debugPrint('Microphone Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in MicrophoneDiagnostic: $e');
      return {
        'permission': false,
        'recorded': false,
        'hasDetectedSound': false,
        'userConfirm': false,
        'error': e.toString(),
      };
    }
  }
}
