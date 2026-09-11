import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/widgets/build_eval_card.dart';
import 'diagnostics_home_controller.dart';
import 'widgets/device_info_section.dart';

/// DiagnosticsHomePage - Giao diện chẩn đoán phần cứng và kiểm định thiết bị
class DiagnosticsHomePage extends GetView<DiagnosticsHomeController> {
  const DiagnosticsHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'diagnostics_title'.tr,
          style: AppTextStyle.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Language switcher button
          IconButton(
            tooltip: 'language'.tr,
            icon: Icon(Icons.language, size: 24.r),
            onPressed: controller.toggleLanguage,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && controller.info.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final osVer = controller.isAndroid
              ? 'Android ${controller.osModel?['release'] ?? ''}'
              : (controller.isIOS
                    ? 'iOS ${controller.osModel?['systemVersion'] ?? ''}'
                    : controller.platform);

          return RefreshIndicator(
            onRefresh: controller.runDiagnostics,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 1. Device Info Header Card
                DeviceInfoSection(
                  modelName: controller.modelName,
                  brand: controller.brand,
                  manufacturer: controller.manufacturer,
                  platform: controller.platform,
                  osVersion: osVer,
                  ramInfo: controller.ramInfo,
                  romInfo: controller.romInfo,
                  origin: controller.origin,
                  marketingName: controller.marketingName,
                ),

                SizedBox(height: 8.h),

                // 2. Hardware Evaluation Section Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Text(
                    'hardware_evaluation'.tr,
                    style: AppTextStyle.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // RAM Evaluation Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: buildEvalCard(
                    title: 'RAM',
                    description: controller.ramInfo?['totalBytes'] != null
                        ? '${(controller.ramInfo!['totalBytes'] / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                        : (controller.ramInfo?['totalGB'] != null
                            ? '${controller.ramInfo!['totalGB']} GB'
                            : 'Đang kiểm tra...'),
                    result: controller.ramEvalResult.value,
                    icon: Icons.memory_rounded,
                  ),
                ),

                // ROM Evaluation Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: buildEvalCard(
                    title: 'Bộ nhớ trong (ROM)',
                    description: controller.romInfo?['totalBytes'] != null
                        ? '${(controller.romInfo!['totalBytes'] / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                        : (controller.isIOS ? 'Miễn đọc trực tiếp (iOS sandbox)' : 'Đang kiểm tra...'),
                    result: controller.romEvalResult.value,
                    icon: Icons.storage_rounded,
                  ),
                ),

                // Wi-Fi Evaluation Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: buildEvalCard(
                    title: 'wifi_test'.tr,
                    description: controller.wifiInfo == null
                        ? 'loading'.tr
                        : (!controller.isWifiEnabled
                            ? 'wifi_desc_disabled'.tr
                            : (controller.isWifiConnected
                                ? 'wifi_desc_connected'.trParams({'ssid': controller.wifiSsid ?? 'Đã kết nối'})
                                : 'wifi_desc_disconnected'.tr)),
                    result: controller.wifiEvalResult.value,
                    icon: Icons.wifi_rounded,
                  ),
                ),

                // Bluetooth Evaluation Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                  child: buildEvalCard(
                    title: 'bluetooth_test'.tr,
                    description: controller.bluetoothInfo == null
                        ? 'loading'.tr
                        : (!controller.isBluetoothEnabled
                            ? 'bluetooth_desc_disabled'.tr
                            : (!controller.hasBluetoothPermission.value
                                ? 'bluetooth_desc_no_perm'.tr
                                : 'bluetooth_desc_scanned'.trParams({'count': '${controller.bluetoothDevicesCount}'}))),
                    result: controller.btEvalResult.value,
                    icon: Icons.bluetooth_rounded,
                  ),
                ),

                SizedBox(height: 16.h),

                // 3. Action Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.goTofuntionCheck,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: controller.isLoading.value
                        ? SizedBox(
                            width: 18.r,
                            height: 18.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(Icons.speed_rounded),
                    label: Text(
                      controller.isLoading.value
                          ? 'loading'.tr
                          : 'recheck_specs'.tr,
                      style: AppTextStyle.button,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          );
        }),
      ),
    );
  }
}
