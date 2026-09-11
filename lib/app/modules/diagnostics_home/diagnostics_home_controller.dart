import 'dart:io';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:my_app/app/routes/app_routes.dart';
import '../../core/localization/app_translations.dart';
import '../../data/services/device_info_helper.dart';
import '../../data/services/device_name_mapper.dart';
import '../../data/services/permission_precheck_service.dart';
import '../../data/services/profile_manager.dart';
import '../../data/services/rule_evaluator.dart';
import 'diagnostics_home_repository.dart';

const _channel = MethodChannel('com.fidobox/diagnostics');

/// Đại diện cho một bước kiểm tra trong quy trình chẩn đoán thiết bị
class DiagStep {
  final String code;
  final String title;
  final Future<void> Function() run;

  DiagStep({
    required this.code,
    required this.title,
    required this.run,
  });
}

/// DiagnosticsHomeController - Điều phối thu thập và chẩn đoán thông số phần cứng thiết bị
class DiagnosticsHomeController extends GetxController {
  final DiagnosticsHomeRepository? repository;

  DiagnosticsHomeController({this.repository});

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final RuleEvaluator _ruleEvaluator = const RuleEvaluator();

  // ==================== REACTIVE STATE ====================
  final isLoading = false.obs;
  final currentStepTitle = ''.obs;
  final info = <String, dynamic>{}.obs;

  // Evaluation results
  final ramEvalResult = Rx<EvalResult?>(null);
  final romEvalResult = Rx<EvalResult?>(null);
  final wifiEvalResult = Rx<EvalResult?>(null);
  final btEvalResult = Rx<EvalResult?>(null);
  final gpsEvalResult = Rx<EvalResult?>(null);
  final vibrateEvalResult = Rx<EvalResult?>(null);

  // Permissions & Services state
  final hasLocationPermission = false.obs;
  final hasBluetoothPermission = false.obs;
  final isLocationServiceEnabled = false.obs;

  // ==================== DERIVED PROPERTIES ====================
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
  Map<String, dynamic>? get wifiInfo => info['wifi'] as Map<String, dynamic>?;
  Map<String, dynamic>? get bluetoothInfo => info['bt'] as Map<String, dynamic>?;
  Map<String, dynamic>? get gpsInfo => info['gps'] as Map<String, dynamic>?;
  Map<String, dynamic>? get vibrateInfo => info['vibrate'] as Map<String, dynamic>?;

  String? get wifiSsid => wifiInfo?['ssid'] as String?;
  bool get isWifiConnected => wifiInfo?['connected'] as bool? ?? false;
  bool get isWifiEnabled => wifiInfo?['enabled'] as bool? ?? false;

  bool get isBluetoothEnabled => bluetoothInfo?['enabled'] as bool? ?? false;
  bool get isBluetoothScanOk => bluetoothInfo?['scanOk'] as bool? ?? false;
  int get bluetoothDevicesCount => bluetoothInfo?['devicesCount'] as int? ?? 0;

  double? get gpsAccuracy => (gpsInfo?['accuracyM'] as num?)?.toDouble();
  bool get isGpsServiceOn => gpsInfo?['serviceOn'] as bool? ?? isLocationServiceEnabled.value;

  bool get isVibrateSupported => vibrateInfo?['supported'] as bool? ?? true;
  bool get isVibrateConfirmed => vibrateInfo?['userConfirm'] as bool? ?? false;

  // ==================== DIAGNOSTIC STEPS ====================
  late final List<DiagStep> diagSteps = [
    DiagStep(
      code: 'ram_rom',
      title: 'RAM & ROM',
      run: _snapRamRom,
    ),
    DiagStep(
      code: 'wifi',
      title: 'Wi-Fi (SSID)',
      run: _snapWifi,
    ),
    DiagStep(
      code: 'bt',
      title: 'Bluetooth (scan)',
      run: _checkBluetooth,
    ),
    DiagStep(
      code: 'gps',
      title: 'Định vị GPS',
      run: _snapGps,
    ),
    // Dòng 355-361: Khai báo bước kiểm định rung
    DiagStep(
      code: 'vibrate',
      title: 'Rung',
      run: _testVibration,
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    runDiagnostics();
  }

  /// Chạy toàn bộ quy trình đo đạc và kiểm định thông số máy
  Future<void> runDiagnostics() async {
    isLoading.value = true;
    try {
      // 1. Dòng 180-195, 197-201: Cập nhật môi trường & kiểm tra trạng thái cấp/từ chối quyền & Location Service
      await _updateEnvironment();

      // 2. Lấy thông tin OS & Model
      final osData = await _getOsAndModel();
      info['osmodel'] = osData;

      // 3. Thực thi từng DiagStep
      for (final step in diagSteps) {
        currentStepTitle.value = step.title;
        await step.run();
      }
    } catch (e) {
      debugPrint('Error running diagnostics: $e');
    } finally {
      isLoading.value = false;
      currentStepTitle.value = '';
    }
  }

  // ==================== ENVIRONMENT & PERMISSIONS ====================

  /// Dòng 180-195: Kiểm tra trạng thái đã cấp hay từ chối của Permission.bluetoothScan và Permission.location
  /// Dòng 197-201: Kiểm tra trạng thái dịch vụ định vị (Location Service) đang Bật hay Tắt
  Future<void> _updateEnvironment() async {
    try {
      hasLocationPermission.value = await PermissionPrecheckService.checkWifiPermission();
      hasBluetoothPermission.value = await PermissionPrecheckService.checkBluetoothPermission();

      // Dòng 197-201: Kiểm tra trạng thái dịch vụ định vị (Location Service)
      bool locationOn = false;
      try {
        locationOn = await Geolocator.isLocationServiceEnabled();
      } catch (_) {}
      isLocationServiceEnabled.value = locationOn;
    } catch (e) {
      debugPrint('Error updating environment permissions: $e');
    }
  }

  // ==================== STEP 1: RAM & ROM ====================

  Future<void> _snapRamRom() async {
    await _snapRam();
    await _snapRom();

    if (ramInfo != null) {
      ramEvalResult.value = _ruleEvaluator.evalRam(ramInfo!);
    }
    if (romInfo != null) {
      romEvalResult.value = _ruleEvaluator.evalRom(romInfo!);
    }
  }

  // ==================== STEP 2: WI-FI TEST ====================

  /// Dòng 744-748: Hàm thực thi _snapWifi() gọi _getWifiInfo()
  Future<bool> _snapWifi() async {
    info['wifi'] = await _getWifiInfo();
    if (wifiInfo != null) {
      wifiEvalResult.value = _ruleEvaluator.evalWifi(wifiInfo!);
    }
    return true;
  }

  /// Dòng 907-920: Logic chi tiết đo và kiểm định Wi-Fi
  Future<Map<String, dynamic>> _getWifiInfo() async {
    try {
      // 1. Gọi native MethodChannel _invoke<bool>('isWifiEnabled') để xem Wi-Fi có bật không
      bool isEnabled = false;
      if (Platform.isAndroid) {
        try {
          isEnabled = await _channel.invokeMethod<bool>('isWifiEnabled') ?? false;
        } catch (_) {
          isEnabled = true; // Fallback
        }
      } else {
        isEnabled = true; // Fallback trên iOS
      }

      // 2. Dùng package connectivity_plus kiểm tra xem thiết bị có đang kết nối Wi-Fi hay không
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult.contains(ConnectivityResult.wifi);

      if (isConnected) {
        isEnabled = true;
      }

      // 3. Dòng 914-916: Trực tiếp gọi await Permission.locationWhenInUse.request() trước khi đọc SSID
      String? ssid;
      bool hasLocation = await Permission.locationWhenInUse.isGranted;
      if (!hasLocation) {
        final reqStatus = await Permission.locationWhenInUse.request();
        hasLocation = reqStatus.isGranted;
      }
      hasLocationPermission.value = hasLocation;

      // Đọc SSID qua NetworkInfo().getWifiName()
      if (isConnected) {
        try {
          final rawSsid = await NetworkInfo().getWifiName();
          if (rawSsid != null) {
            ssid = rawSsid.replaceAll('"', '').trim();
          }
        } catch (e) {
          debugPrint('Error getting Wi-Fi SSID: $e');
        }
      }

      final data = {
        'enabled': isEnabled,
        'connected': isConnected,
        'ssid': ssid,
        'hasLocationPermission': hasLocation,
        'requiresLocationStrict': ProfileManager.requiresLocationForWifi(brand),
      };

      debugPrint('Wi-Fi Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in _getWifiInfo: $e');
      return {
        'enabled': false,
        'connected': false,
        'ssid': null,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 3: BLUETOOTH TEST ====================

  /// Dòng 760-763: Hàm thực thi _checkBluetooth() gọi _getBluetoothInfo()
  Future<bool> _checkBluetooth() async {
    info['bt'] = await _getBluetoothInfo();
    if (bluetoothInfo != null) {
      btEvalResult.value = _ruleEvaluator.evalBluetooth(bluetoothInfo!);
    }
    return true;
  }

  /// Dòng 938-955: Logic chi tiết đo và quét Bluetooth
  Future<Map<String, dynamic>> _getBluetoothInfo() async {
    try {
      // 1. Tiền kiểm tra và xin quyền Bluetooth
      final hasPermission = await PermissionPrecheckService.requestBluetoothPermission();
      hasBluetoothPermission.value = hasPermission;

      // 2. Dùng package flutter_blue_plus kiểm tra adapter Bluetooth có bật không
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

      // 3. Chạy hàm quét thực tế trong 2 giây: startScan -> delayed(2s) -> stopScan
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
      debugPrint('Error in _getBluetoothInfo: $e');
      return {
        'enabled': false,
        'scanOk': false,
        'hasScanPermission': false,
        'devicesCount': 0,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 4: GPS TEST ====================

  Future<bool> _snapGps() async {
    info['gps'] = await _getLocationAccuracy();
    if (gpsInfo != null) {
      gpsEvalResult.value = _ruleEvaluator.evalGps(gpsInfo!);
    }
    return true;
  }

  /// Dòng 984-997: Hàm _getLocationAccuracy() thực hiện kiểm tra và trực tiếp xin quyền runtime qua geolocator
  Future<Map<String, dynamic>> _getLocationAccuracy() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      final svc = await Geolocator.isLocationServiceEnabled();
      isLocationServiceEnabled.value = svc;

      double? accuracy;
      if (svc && (perm == LocationPermission.always || perm == LocationPermission.whileInUse)) {
        try {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 5),
            ),
          );
          accuracy = pos.accuracy;
        } catch (_) {}
      }

      final data = {
        'serviceOn': svc,
        'accuracyM': accuracy,
        'permission': perm.name,
      };

      debugPrint('GPS Diagnostic Info: $data');
      return data;
    } catch (e) {
      debugPrint('Error in _getLocationAccuracy: $e');
      return {
        'serviceOn': false,
        'accuracyM': null,
        'error': e.toString(),
      };
    }
  }

  // ==================== STEP 5: VIBRATION TEST ====================

  /// Dòng 1023-1052: Hàm _testVibration() kiểm tra phần cứng rung và kích hoạt rung ngẫu nhiên (1–3 lần) rồi hỏi người dùng xác nhận
  Future<bool> _testVibration() async {
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator) {
        info['vibrate'] = {'supported': false, 'userConfirm': false};
        vibrateEvalResult.value = _ruleEvaluator.evalVibration(info['vibrate']!);
        return false;
      }

      final vibrationCount = math.Random().nextInt(3) + 1; // Rung ngẫu nhiên 1..3 lần
      for (var i = 0; i < vibrationCount; i++) {
        await Vibration.vibrate(duration: 300);
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final result = await Get.dialog<int>(
        AlertDialog(
          title: const Text('Kiểm tra rung'),
          content: const Text('Máy vừa rung bao nhiêu lần?'),
          actions: [0, 1, 2, 3]
              .map((n) => TextButton(
                    onPressed: () => Get.back(result: n),
                    child: Text(n == 0 ? 'Không rung' : '$n lần'),
                  ))
              .toList(),
        ),
        barrierDismissible: false,
      );

      final isMatched = result == vibrationCount;
      info['vibrate'] = {
        'supported': true,
        'vibrationCount': vibrationCount,
        'userSelection': result,
        'userConfirm': isMatched,
      };

      vibrateEvalResult.value = _ruleEvaluator.evalVibration(info['vibrate']!);
      debugPrint('Vibration Diagnostic Info: ${info['vibrate']}');
      return isMatched;
    } catch (e) {
      debugPrint('Error in _testVibration: $e');
      info['vibrate'] = {'supported': false, 'userConfirm': false, 'error': e.toString()};
      vibrateEvalResult.value = _ruleEvaluator.evalVibration(info['vibrate']!);
      return false;
    }
  }

  // ==================== OS & MODEL ====================

  /// Lấy phiên bản hệ điều hành, nhà sản xuất, xuất xứ...
  Future<Map<String, dynamic>> _getOsAndModel() async {
    try {
      if (Platform.isAndroid) {
        final a = await _deviceInfo.androidInfo;
        final vendor = a.manufacturer.toLowerCase();
        final marketingName = DeviceNameMapper.getMarketingName(
          a.model,
          a.brand,
        );

        final data = {
          'platform': 'android',
          'sdk': a.version.sdkInt,
          'release': a.version.release,
          'model': a.model,
          'brand': a.brand,
          'manufacturer': a.manufacturer,
          'vendor': vendor,
          'marketingName': marketingName,
          'ram': ramInfo,
          'rom': romInfo,
        };

        debugPrint('Android Device Info: $data');
        return data;
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        final machine = i.utsname.machine;
        final friendlyName = await DeviceInfoHelper.getModel();

        final data = {
          'platform': 'ios',
          'systemVersion': i.systemVersion,
          'model': machine,
          'marketingName': friendlyName,
          'name': i.name,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'vendor': 'apple',
          'isSamsung': false,
          'isApple': true,
        };

        debugPrint('iOS Device Info: $data');
        return data;
      }

      return {'platform': 'unknown', 'origin': 'Không xác định'};
    } catch (e) {
      debugPrint('Error fetching OS & Model: $e');
      return {'platform': 'error', 'error': e.toString()};
    }
  }

  // ==================== RAM & ROM HELPERS ====================

  Future<Map<String, dynamic>> _getRamInfo() async {
    try {
      return await DeviceInfoHelper.getRamInfo();
    } catch (_) {
      return const {'freeBytes': null, 'totalBytes': null, 'source': 'error'};
    }
  }

  Future<Map<String, dynamic>> _getRomInfo() async {
    try {
      return await DeviceInfoHelper.getRomInfo();
    } catch (_) {
      return const {'freeBytes': null, 'totalBytes': null, 'source': 'error'};
    }
  }

  Future<bool> _snapRam() async {
    info['ram'] = await _getRamInfo();
    return true;
  }

  Future<bool> _snapRom() async {
    info['rom'] = await _getRomInfo();
    return true;
  }

  // ==================== UTILS ====================

  /// Chuyển đổi ngôn ngữ ứng dụng (Tiếng Việt <-> Tiếng Anh)
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

  /// Chuyển đến màn hình kiểm tra chức năng
  void goTofuntionCheck() {
    Get.toNamed(AppRoutes.functionCheck);
  }
}
