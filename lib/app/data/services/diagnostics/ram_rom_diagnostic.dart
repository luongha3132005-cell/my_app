import '../device_info_helper.dart';

/// Chuyên trách đọc và thu thập thông số bộ nhớ RAM & ROM của thiết bị
class RamRomDiagnostic {
  const RamRomDiagnostic();

  /// Đọc thông số bộ nhớ RAM (dung lượng tổng, còn trống, nguồn đọc thực hay ước tính)
  Future<Map<String, dynamic>> checkRam() async {
    try {
      return await DeviceInfoHelper.getRamInfo();
    } catch (_) {
      return const {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'error',
      };
    }
  }

  /// Đọc thông số bộ nhớ trong ROM (dung lượng tổng, còn trống)
  Future<Map<String, dynamic>> checkRom() async {
    try {
      return await DeviceInfoHelper.getRomInfo();
    } catch (_) {
      return const {
        'freeBytes': null,
        'totalBytes': null,
        'source': 'error',
      };
    }
  }
}
