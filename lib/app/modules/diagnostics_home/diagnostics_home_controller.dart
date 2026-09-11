import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:my_app/app/routes/app_routes.dart';
import '../../core/localization/app_translations.dart';
import '../../data/services/diagnostics/device_os_diagnostic.dart';
import '../../data/services/diagnostics/ram_rom_diagnostic.dart';
import '../../data/services/rule_evaluator.dart';
import 'diagnostics_home_repository.dart';

/// DiagnosticsHomeController - Quản lý thông tin tổng quan thiết bị (Device Overview) cho Trang chủ
class DiagnosticsHomeController extends GetxController {
  final DiagnosticsHomeRepository? repository;
  final RamRomDiagnostic _ramRomDiag;
  final DeviceOsDiagnostic _deviceOsDiag;
  final RuleEvaluator _ruleEvaluator;

  DiagnosticsHomeController({
    this.repository,
    RamRomDiagnostic? ramRomDiag,
    DeviceOsDiagnostic? deviceOsDiag,
    RuleEvaluator? ruleEvaluator,
  }) : _ramRomDiag = ramRomDiag ?? const RamRomDiagnostic(),
       _deviceOsDiag = deviceOsDiag ?? DeviceOsDiagnostic(),
       _ruleEvaluator = ruleEvaluator ?? const RuleEvaluator();

  // ==================== REACTIVE STATE (Rx) ====================
  final isLoading = false.obs;
  final info = <String, dynamic>{}.obs;

  // Kết quả đánh giá thông số cấu hình bộ nhớ
  final ramEvalResult = Rx<EvalResult?>(null);
  final romEvalResult = Rx<EvalResult?>(null);

  // ==================== GETTERS (UI DATA BINDING) ====================
  Map<String, dynamic>? get osModel => info['osmodel'] as Map<String, dynamic>?;

  bool get isAndroid => osModel?['platform'] == 'android';
  bool get isIOS => osModel?['platform'] == 'ios';
  String get platform => (osModel?['platform'] as String?) ?? 'unknown';
  String get vendor => (osModel?['vendor'] as String?) ?? '';
  String get brand => (osModel?['brand'] as String?) ?? '';
  String get manufacturer => (osModel?['manufacturer'] as String?) ?? '';
  String get modelName => (osModel?['model'] as String?) ?? '';
  String get marketingName => (osModel?['marketingName'] as String?) ?? '';
  String get origin => (osModel?['origin'] as String?) ?? 'Chính hãng';
  bool get isSamsung => vendor.toLowerCase() == 'samsung';
  bool get isApple => vendor.toLowerCase() == 'apple' || isIOS;

  Map<String, dynamic>? get ramInfo => info['ram'] as Map<String, dynamic>?;
  Map<String, dynamic>? get romInfo => info['rom'] as Map<String, dynamic>?;

  @override
  void onInit() {
    super.onInit();
    fetchDeviceInfo();
  }

  /// Thu thập thông số cấu hình phần cứng cơ bản của thiết bị
  Future<void> fetchDeviceInfo() async {
    isLoading.value = true;
    try {
      // 1. Đọc RAM & ROM
      final ram = await _ramRomDiag.checkRam();
      final rom = await _ramRomDiag.checkRom();
      info['ram'] = ram;
      info['rom'] = rom;

      ramEvalResult.value = _ruleEvaluator.evalRam(ram);
      romEvalResult.value = _ruleEvaluator.evalRom(rom);

      // 2. Nhận diện hệ điều hành và tên thương mại
      final osData = await _deviceOsDiag.getOsAndModel(
        ramInfo: ram,
        romInfo: rom,
      );
      info['osmodel'] = osData;
    } catch (e) {
      debugPrint('Error fetching device info: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== UTILS & NAVIGATION ====================

  /// Chuyển đổi ngôn ngữ ứng dụng
  void toggleLanguage() {
    final currentLocale = Get.locale;
    if (currentLocale?.languageCode == 'vi') {
      Get.updateLocale(AppTranslations.enLocale);
    } else {
      Get.updateLocale(AppTranslations.viLocale);
    }
  }

  /// Chuyển đổi chế độ giao diện Sáng / Tối
  void toggleTheme() {
    Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  /// Chuyển sang màn hình kiểm tra chức năng (Function Check)
  void goToFunctionCheck() {
    Get.toNamed(AppRoutes.functionCheck, arguments: {'brand': brand});
  }

  /// Tên gọi cũ để đảm bảo tương thích
  void goTofuntionCheck() => goToFunctionCheck();

  /// Giữ hàm runDiagnostics để tương thích nếu các widget cũ gọi refresh
  Future<void> runDiagnostics() => fetchDeviceInfo();
}
