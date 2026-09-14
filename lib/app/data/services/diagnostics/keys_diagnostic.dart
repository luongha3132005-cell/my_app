import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../routes/app_routes.dart';

/// Dịch vụ chẩn đoán phím vật lý (Tăng/Giảm âm lượng, Nguồn, Quay lại)
class KeysDiagnostic {
  const KeysDiagnostic();

  /// Kích hoạt quy trình kiểm tra phím vật lý:
  /// Chuyển tới màn hình KeysTestPage và chờ kết quả trả về
  Future<Map<String, dynamic>> checkKeys() async {
    try {
      final result = await Get.toNamed(AppRoutes.keysTest);

      final data = (result is Map<String, dynamic>)
          ? result
          : {
              'userConfirm': false,
              'volumeUp': false,
              'volumeDown': false,
              'back': false,
              'powerManualConfirm': false,
            };

      debugPrint('Keys Diagnostic Result: $data');
      return data;
    } catch (e) {
      debugPrint('Error in KeysDiagnostic: $e');
      return {
        'userConfirm': false,
        'volumeUp': false,
        'volumeDown': false,
        'back': false,
        'powerManualConfirm': false,
        'error': e.toString(),
      };
    }
  }
}
