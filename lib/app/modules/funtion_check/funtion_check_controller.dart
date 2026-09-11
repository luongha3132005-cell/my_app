import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/localization/app_translations.dart';
import '../../data/services/diagnostics/bluetooth_diagnostic.dart';
import '../../data/services/diagnostics/diag_step.dart';
import '../../data/services/diagnostics/gps_diagnostic.dart';
import '../../data/services/diagnostics/ram_rom_diagnostic.dart';
import '../../data/services/diagnostics/vibration_diagnostic.dart';
import '../../data/services/diagnostics/wifi_diagnostic.dart';
import '../../data/services/rule_evaluator.dart';

/// Controller quản lý toàn bộ 6 bài kiểm tra phần cứng (RAM, ROM, Wi-Fi, Bluetooth, GPS, Rung)
class FuntionCheckController extends GetxController {
  final RamRomDiagnostic _ramRomDiag;
  final WifiDiagnostic _wifiDiag;
  final BluetoothDiagnostic _bluetoothDiag;
  final GpsDiagnostic _gpsDiag;
  final VibrationDiagnostic _vibrationDiag;
  final RuleEvaluator _ruleEvaluator;

  FuntionCheckController({
    RamRomDiagnostic? ramRomDiag,
    WifiDiagnostic? wifiDiag,
    BluetoothDiagnostic? bluetoothDiag,
    GpsDiagnostic? gpsDiag,
    VibrationDiagnostic? vibrationDiag,
    RuleEvaluator? ruleEvaluator,
  })  : _ramRomDiag = ramRomDiag ?? const RamRomDiagnostic(),
        _wifiDiag = wifiDiag ?? WifiDiagnostic(),
        _bluetoothDiag = bluetoothDiag ?? const BluetoothDiagnostic(),
        _gpsDiag = gpsDiag ?? const GpsDiagnostic(),
        _vibrationDiag = vibrationDiag ?? const VibrationDiagnostic(),
        _ruleEvaluator = ruleEvaluator ?? const RuleEvaluator();

  // ==================== REACTIVE STATE (Rx) ====================
  final hasStartedCheck = false.obs;
  final isLoading = false.obs;
  final currentStepTitle = ''.obs;
  final brandName = ''.obs;

  // Kết quả đánh giá của 6 bài kiểm tra (Pass / Fail / Warning / Skip)
  final ramEvalResult = Rx<EvalResult?>(null);
  final romEvalResult = Rx<EvalResult?>(null);
  final wifiEvalResult = Rx<EvalResult?>(null);
  final btEvalResult = Rx<EvalResult?>(null);
  final gpsEvalResult = Rx<EvalResult?>(null);
  final vibrateEvalResult = Rx<EvalResult?>(null);

  // Raw data info
  final ramInfo = Rx<Map<String, dynamic>?>(null);
  final romInfo = Rx<Map<String, dynamic>?>(null);
  final wifiInfo = Rx<Map<String, dynamic>?>(null);
  final bluetoothInfo = Rx<Map<String, dynamic>?>(null);
  final gpsInfo = Rx<Map<String, dynamic>?>(null);
  final vibrateInfo = Rx<Map<String, dynamic>?>(null);

  // Quyền và trạng thái hệ thống
  final hasLocationPermission = false.obs;
  final hasBluetoothPermission = false.obs;
  final isLocationServiceEnabled = false.obs;

  // ==================== GETTERS ====================
  String? get wifiSsid => wifiInfo.value?['ssid'] as String?;
  bool get isWifiConnected => wifiInfo.value?['connected'] as bool? ?? false;
  bool get isWifiEnabled => wifiInfo.value?['enabled'] as bool? ?? false;

  bool get isBluetoothEnabled => bluetoothInfo.value?['enabled'] as bool? ?? false;
  bool get isBluetoothScanOk => bluetoothInfo.value?['scanOk'] as bool? ?? false;
  int get bluetoothDevicesCount => bluetoothInfo.value?['devicesCount'] as int? ?? 0;

  double? get gpsAccuracy => (gpsInfo.value?['accuracyM'] as num?)?.toDouble();
  bool get isGpsServiceOn => gpsInfo.value?['serviceOn'] as bool? ?? isLocationServiceEnabled.value;

  bool get isVibrateSupported => vibrateInfo.value?['supported'] as bool? ?? true;
  bool get isVibrateConfirmed => vibrateInfo.value?['userConfirm'] as bool? ?? false;

  // ==================== DANH SÁCH 6 BÀI KIỂM ĐỊNH ====================
  late final List<DiagStep> functionSteps = [
    DiagStep(
      code: 'ram',
      title: 'ram_test'.tr,
      run: _checkRam,
    ),
    DiagStep(
      code: 'rom',
      title: 'rom_test'.tr,
      run: _checkRom,
    ),
    DiagStep(
      code: 'wifi',
      title: 'wifi_test'.tr,
      run: _checkWifi,
    ),
    DiagStep(
      code: 'bt',
      title: 'bluetooth_test'.tr,
      run: _checkBluetooth,
    ),
    DiagStep(
      code: 'gps',
      title: 'gps_test'.tr,
      run: _checkGps,
    ),
    DiagStep(
      code: 'vibrate',
      title: 'vibrate_test'.tr,
      run: _checkVibration,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['brand'] != null) {
      brandName.value = args['brand'].toString();
    }
  }

  /// Bắt đầu chạy quy trình kiểm định khi người dùng ấn nút "Bắt đầu kiểm tra"
  Future<void> startDiagnostics() async {
    hasStartedCheck.value = true;
    await runFunctionCheck();
  }

  /// Thực thi toàn bộ quy trình 6 bài kiểm tra
  Future<void> runFunctionCheck() async {
    if (isLoading.value) return;
    if (!hasStartedCheck.value) return;
    isLoading.value = true;
    try {
      for (final step in functionSteps) {
        currentStepTitle.value = step.title;
        await step.run();
      }
    } catch (e) {
      debugPrint('Error running function check: $e');
    } finally {
      isLoading.value = false;
      currentStepTitle.value = '';
    }
  }

  // ==================== 6 BÀI TEST CHI TIẾT ====================

  /// 1. Kiểm tra RAM
  Future<void> _checkRam() async {
    final result = await _ramRomDiag.checkRam();
    ramInfo.value = result;
    ramEvalResult.value = _ruleEvaluator.evalRam(result);
  }

  /// 2. Kiểm tra ROM
  Future<void> _checkRom() async {
    final result = await _ramRomDiag.checkRom();
    romInfo.value = result;
    romEvalResult.value = _ruleEvaluator.evalRom(result);
  }

  /// 3. Kiểm tra Wi-Fi & Đọc SSID
  Future<void> _checkWifi() async {
    final result = await _wifiDiag.checkWifi(brand: brandName.value);
    wifiInfo.value = result;
    hasLocationPermission.value = result['hasLocationPermission'] as bool? ?? false;
    wifiEvalResult.value = _ruleEvaluator.evalWifi(result);
  }

  /// 4. Kiểm tra Bluetooth & Quét thiết bị 2 giây
  Future<void> _checkBluetooth() async {
    final result = await _bluetoothDiag.checkBluetooth(brand: brandName.value);
    bluetoothInfo.value = result;
    hasBluetoothPermission.value = result['hasScanPermission'] as bool? ?? false;
    btEvalResult.value = _ruleEvaluator.evalBluetooth(result);
  }

  /// 5. Kiểm tra định vị GPS & Đo sai số mét
  Future<void> _checkGps() async {
    final result = await _gpsDiag.checkGps();
    gpsInfo.value = result;
    isLocationServiceEnabled.value = result['serviceOn'] as bool? ?? false;
    gpsEvalResult.value = _ruleEvaluator.evalGps(result);
  }

  /// 6. Kiểm tra Rung & Dialog tương tác
  Future<void> _checkVibration() async {
    final result = await _vibrationDiag.checkVibration();
    vibrateInfo.value = result;
    vibrateEvalResult.value = _ruleEvaluator.evalVibration(result);
  }

  // ==================== UTILS ====================
  void toggleLanguage() {
    final currentLocale = Get.locale;
    if (currentLocale?.languageCode == 'vi') {
      Get.updateLocale(AppTranslations.enLocale);
    } else {
      Get.updateLocale(AppTranslations.viLocale);
    }
  }
}
