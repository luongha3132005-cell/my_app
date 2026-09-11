import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibration/vibration.dart';

/// Chuyên trách kiểm tra mô-tơ rung vật lý và kích hoạt hộp thoại tương tác hỏi người dùng
class VibrationDiagnostic {
  const VibrationDiagnostic();

  /// Kích hoạt rung ngẫu nhiên 1–3 lần và hiện Dialog hỏi người dùng xác nhận
  Future<Map<String, dynamic>> checkVibration() async {
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator) {
        return {
          'supported': false,
          'userConfirm': false,
        };
      }

      final vibrationCount = math.Random().nextInt(3) + 1; // Rung ngẫu nhiên 1..3 lần
      for (var i = 0; i < vibrationCount; i++) {
        await Vibration.vibrate(duration: 300);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final result = await Get.dialog<int>(
        AlertDialog(
          title: Text('vibrate_dialog_title'.tr),
          content: Text('vibrate_dialog_content'.tr),
          actions: [0, 1, 2, 3]
              .map((n) => TextButton(
                    onPressed: () => Get.back(result: n),
                    child: Text(n == 0
                        ? 'vibrate_no_vibration'.tr
                        : 'vibrate_count_times'.trParams({'count': '$n'})),
                  ))
              .toList(),
        ),
        barrierDismissible: false,
      );

      final isMatched = result == vibrationCount;
      final data = {
        'supported': true,
        'vibrationCount': vibrationCount,
        'userSelection': result,
        'userConfirm': isMatched,
      };

      debugPrint('Vibration Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in VibrationDiagnostic: $e');
      return {
        'supported': false,
        'userConfirm': false,
        'error': e.toString(),
      };
    }
  }
}
