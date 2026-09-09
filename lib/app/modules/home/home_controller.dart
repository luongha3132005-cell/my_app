import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/localization/app_translations.dart';
import '../../data/services/device_info_helper.dart';
import '../../data/services/device_name_mapper.dart';

/// Controller managing Home module state and interactions
class HomeController extends GetxController {
  // Reactive counter state
  final counter = 0.obs;

  // Device specs reactive state (RAM, ROM, OS, Model)
  final isLoadingSpecs = false.obs;
  final modelName = ''.obs;
  final brand = ''.obs;
  final manufacturer = ''.obs;
  final platform = ''.obs;
  final osVersion = ''.obs;
  final marketingName = ''.obs;
  final origin = ''.obs;
  final ramInfo = Rx<Map<String, dynamic>?>(null);
  final romInfo = Rx<Map<String, dynamic>?>(null);

  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  @override
  void onInit() {
    super.onInit();
    fetchDeviceSpecs();
  }

  /// Nạp thông số phần cứng thiết bị (RAM, ROM, OS, Model)
  Future<void> fetchDeviceSpecs() async {
    isLoadingSpecs.value = true;
    try {
      // 1. Đo đạc RAM & ROM qua DeviceInfoHelper
      ramInfo.value = await DeviceInfoHelper.getRamInfo();
      romInfo.value = await DeviceInfoHelper.getRomInfo();

      // 2. Lấy thông tin OS & Model
      if (Platform.isAndroid) {
        final a = await _deviceInfo.androidInfo;
        platform.value = 'Android';
        osVersion.value = 'Android ${a.version.release} (SDK ${a.version.sdkInt})';
        modelName.value = a.model;
        brand.value = a.brand;
        manufacturer.value = a.manufacturer;
        origin.value = _getOriginCountry(a.brand, a.manufacturer);
        marketingName.value = DeviceNameMapper.getMarketingName(a.model, a.brand);
      } else if (Platform.isIOS) {
        final i = await _deviceInfo.iosInfo;
        platform.value = 'iOS';
        osVersion.value = 'iOS ${i.systemVersion}';
        modelName.value = i.utsname.machine;
        brand.value = 'Apple';
        manufacturer.value = 'Apple';
        origin.value = 'Mỹ';
        marketingName.value = await DeviceInfoHelper.getModel();
      } else {
        platform.value = Platform.operatingSystem;
        osVersion.value = Platform.operatingSystemVersion;
        modelName.value = 'Desktop';
        brand.value = 'Unknown';
        manufacturer.value = 'Unknown';
        origin.value = 'Không xác định';
        marketingName.value = 'Thiết bị ${Platform.operatingSystem}';
      }
    } catch (e) {
      debugPrint('Error fetching device specs: $e');
    } finally {
      isLoadingSpecs.value = false;
    }
  }

  String _getOriginCountry(String brand, String manufacturer) {
    final b = brand.toLowerCase();
    final m = manufacturer.toLowerCase();
    bool has(String s) => b.contains(s) || m.contains(s);

    if (has('samsung') || has('lg')) return 'Hàn Quốc';
    if (has('xiaomi') ||
        has('oppo') ||
        has('vivo') ||
        has('huawei') ||
        has('oneplus') ||
        has('realme') ||
        has('honor') ||
        has('zte') ||
        has('lenovo') ||
        has('meizu') ||
        has('tcl')) {
      return 'Trung Quốc';
    }
    if (has('apple') || has('google') || has('motorola')) return 'Mỹ';
    if (has('sony') || has('sharp') || has('fujitsu')) return 'Nhật Bản';
    if (has('asus') || has('htc') || has('acer')) return 'Đài Loan';
    if (has('nokia')) return 'Phần Lan';
    return 'Không xác định';
  }

  /// Increment counter value
  void increment() {
    counter.value++;
  }

  /// Reset counter value
  void reset() {
    counter.value = 0;
  }

  /// Toggle app language between English and Vietnamese
  void toggleLanguage() {
    final newLocale = Get.locale?.languageCode == 'vi'
        ? AppTranslations.enLocale
        : AppTranslations.viLocale;
    Get.updateLocale(newLocale);
  }

  /// Toggle theme between light and dark modes
  void toggleTheme() {
    Get.changeThemeMode(
      Get.isDarkMode ? ThemeMode.light : ThemeMode.dark,
    );
  }
}
