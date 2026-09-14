import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Chuyên trách kiểm tra tính năng phần cứng sinh trắc học (Vân tay, Face ID...)
class BiometricDiagnostic {
  final LocalAuthentication _localAuth;

  BiometricDiagnostic({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  /// Kiểm tra tĩnh tính khả dụng của phần cứng sinh trắc học
  /// Không hiển thị popup quét vân tay/mặt để đảm bảo chạy mượt mà trong quy trình chẩn đoán tự động
  Future<Map<String, dynamic>> checkBiometrics() async {
    bool canCheck = false;
    bool supported = false;
    List<String> availableBiometrics = [];

    try {
      // 1. Kiểm tra phần cứng máy có hỗ trợ công nghệ sinh trắc học không
      supported = await _localAuth.isDeviceSupported();

      // 2. Kiểm tra thiết bị có cảm biến VÀ người dùng đã cài đặt vân tay/mặt trong Cài đặt
      canCheck = await _localAuth.canCheckBiometrics;

      // 3. Lấy danh sách các loại sinh trắc học được hỗ trợ (fingerprint, face, iris, strong, weak...)
      final bios = await _localAuth.getAvailableBiometrics();
      availableBiometrics = bios.map((b) => b.name).toList();
    } catch (e) {
      debugPrint('Error in BiometricDiagnostic: $e');
    }

    final data = {
      'canCheck': canCheck,
      'supported': supported,
      'availableBiometrics': availableBiometrics,
    };

    debugPrint('Biometric Diagnostic Info: $data');
    return data;
  }
}
