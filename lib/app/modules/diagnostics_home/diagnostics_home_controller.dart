import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/device_info_helper.dart';
import '../../data/services/device_name_mapper.dart';
import '../../data/services/rule_evaluator.dart';
import 'diagnostics_home_repository.dart';

/// DiagnosticsHomeController - Điều phối thu thập và chẩn đoán thông số phần cứng thiết bị
class DiagnosticsHomeController extends GetxController {
  final DiagnosticsHomeRepository? repository;

  DiagnosticsHomeController({this.repository});

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final RuleEvaluator _ruleEvaluator = const RuleEvaluator();

  // ==================== REACTIVE STATE ====================
  final isLoading = false.obs;
  final info = <String, dynamic>{}.obs;
  final ramEvalResult = Rx<EvalResult?>(null);
  final romEvalResult = Rx<EvalResult?>(null);

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

  @override
  void onInit() {
    super.onInit();
    runDiagnostics();
  }

  /// Chạy toàn bộ quy trình đo đạc và kiểm định thông số máy
  Future<void> runDiagnostics() async {
    isLoading.value = true;
    try {
      // 1. Lấy thông tin OS & Model
      final osData = await _getOsAndModel();
      info['osmodel'] = osData;

      // 2. Chụp thông số RAM & ROM
      await _snapRam();
      await _snapRom();

      // 3. Đánh giá chất lượng RAM & ROM qua RuleEvaluator
      if (ramInfo != null) {
        ramEvalResult.value = _ruleEvaluator.evalRam(ramInfo!);
      }
      if (romInfo != null) {
        romEvalResult.value = _ruleEvaluator.evalRom(romInfo!);
      }
    } catch (e) {
      debugPrint('Error running diagnostics: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ==================== OS & MODEL ====================

  /// Lấy phiên bản hệ điều hành (Android SDK/release hoặc iOS systemVersion), nhà sản xuất, xuất xứ...
  Future<Map<String, dynamic>> _getOsAndModel() async {
    try {
      if (Platform.isAndroid) {
        final a = await _deviceInfo.androidInfo;
        final vendor = a.manufacturer.toLowerCase();
        // final origin = _getOriginCountry(a.brand, a.manufacturer);
        final marketingName = DeviceNameMapper.getMarketingName(
          a.model,
          a.brand,
        );

        return {
          'platform': 'android',
          'sdk': a.version.sdkInt,
          'release': a.version.release,
          'model': a.model,
          'marketingName': marketingName,
          'brand': a.brand,
          'manufacturer': a.manufacturer,
          'vendor': vendor,
          //    'origin': origin,
          'isSamsung': vendor == 'samsung',
          'isApple': false,
        };
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        final machine = i.utsname.machine;
        final friendlyName = await DeviceInfoHelper.getModel();

        return {
          'platform': 'ios',
          'systemVersion': i.systemVersion,
          'model': machine,
          'marketingName': friendlyName,
          'name': i.name,
          'brand': 'Apple',
          'manufacturer': 'Apple',
          'vendor': 'apple',
          //  'origin': 'Mỹ',
          'isSamsung': false,
          'isApple': true,
        };
      }

      return {'platform': 'unknown', 'origin': 'Không xác định'};
    } catch (e) {
      debugPrint('Error fetching OS & Model: $e');
      return {'platform': 'error', 'error': e.toString()};
    }
  }

  /// Xác định quốc gia xuất xứ dựa trên thương hiệu và nhà sản xuất
  // String _getOriginCountry(String brand, String manufacturer) {
  //   final b = brand.toLowerCase();
  //   final m = manufacturer.toLowerCase();
  //   bool has(String s) => b.contains(s) || m.contains(s);

  //   if (has('samsung') || has('lg')) return 'Hàn Quốc';
  //   if (has('xiaomi') ||
  //       has('oppo') ||
  //       has('vivo') ||
  //       sm-a365n
  //       has('huawei') ||
  //       has('oneplus') ||
  //       has('realme') ||
  //       has('honor') ||
  //       has('zte') ||
  //       has('lenovo') ||
  //       has('meizu') ||
  //       has('tcl')) {
  //     return 'Trung Quốc';
  //   }
  //   if (has('apple') || has('google') || has('motorola')) return 'Mỹ';
  //   if (has('sony') || has('sharp') || has('fujitsu')) return 'Nhật Bản';
  //   if (has('asus') || has('htc') || has('acer')) return 'Đài Loan';
  //   if (has('nokia')) return 'Phần Lan';
  //   return 'Không xác định';
  // }

  // ==================== RAM & ROM ====================

  /// Lấy thông tin chi tiết RAM
  Future<Map<String, dynamic>> _getRamInfo() async {
    try {
      return await DeviceInfoHelper.getRamInfo();
    } catch (_) {
      return const {'freeBytes': null, 'totalBytes': null, 'source': 'error'};
    }
  }

  /// Lấy thông tin chi tiết ROM (Bộ nhớ trong)
  Future<Map<String, dynamic>> _getRomInfo() async {
    try {
      return await DeviceInfoHelper.getRomInfo();
    } catch (_) {
      return const {'freeBytes': null, 'totalBytes': null, 'source': 'error'};
    }
  }

  /// Thực hiện chụp/đo thông số RAM
  Future<bool> _snapRam() async {
    info['ram'] = await _getRamInfo();
    return true;
  }

  /// Thực hiện chụp/đo thông số ROM
  Future<bool> _snapRom() async {
    info['rom'] = await _getRomInfo();
    return true;
  }
}
