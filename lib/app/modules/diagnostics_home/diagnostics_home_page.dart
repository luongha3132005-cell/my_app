import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_text_style.dart';
import 'diagnostics_home_controller.dart';
import 'widgets/device_info_section.dart';
import 'widgets/start_function_check_button.dart';

/// DiagnosticsHomePage - Trang chủ hiển thị thông tin cấu hình và tổng quan thiết bị
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
            onRefresh: controller.fetchDeviceInfo,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 1. Thẻ thông tin cấu hình máy chi tiết
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

                SizedBox(height: 16.h),

                // 3. Nút chính chuyển sang màn hình Kiểm Tra Chức Năng (Function Check)
                StartFunctionCheckButton(
                  isLoading: controller.isLoading.value,
                  onPressed: controller.goToFunctionCheck,
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
