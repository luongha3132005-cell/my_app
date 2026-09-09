import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:my_app/app/modules/home/widget/build_info_row.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../diagnostics_home/widgets/device_info_section.dart';
import 'home_controller.dart';

/// Home view page with responsive layout using flutter_screenutil
class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TuyetHa',
          style: AppTextStyle.titleLarge.copyWith(
            color: AppColor.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Language switcher button
          IconButton(
            tooltip: 'language'.tr,
            icon: Icon(Icons.language, size: 24.r),
            onPressed: controller.toggleLanguage,
          ),
          // Theme mode toggle button
          IconButton(
            tooltip: 'theme'.tr,
            icon: Icon(
              Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 24.r,
            ),
            onPressed: controller.toggleTheme,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20.w),
          children: [
            // Welcome Hero Banner
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 16.r,
                    offset: Offset(0, 8.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.flutter_dash,
                        color: AppColors.white,
                        size: 36.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'nav_home'.tr,
                          style: AppTextStyle.headlineSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'login_subtitle'.tr,
                    style: AppTextStyle.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Device Info Banner (RAM, ROM, OS, Model)
            Obx(
              () => DeviceInfoSection(
                modelName: controller.modelName.value,
                brand: controller.brand.value,
                manufacturer: controller.manufacturer.value,
                platform: controller.platform.value,
                osVersion: controller.osVersion.value,
                ramInfo: controller.ramInfo.value,
                romInfo: controller.romInfo.value,
                origin: controller.origin.value,
                marketingName: controller.marketingName.value,
              ),
            ),

            SizedBox(height: 12.h),

            // Detailed RAM, ROM & OS Specs Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.memory_rounded,
                              color: AppColor.primary,
                              size: 20.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Thông số RAM, ROM & OS',
                              style: AppTextStyle.titleSmall.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Obx(
                          () => IconButton(
                            icon: controller.isLoadingSpecs.value
                                ? SizedBox(
                                    width: 16.r,
                                    height: 16.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.refresh_rounded, size: 20.r),
                            onPressed: controller.isLoadingSpecs.value
                                ? null
                                : controller.fetchDeviceSpecs,
                            tooltip: 'Làm mới thông số',
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 16.h),
                    Obx(() {
                      final ram = controller.ramInfo.value;
                      final rom = controller.romInfo.value;

                      String ramText = 'Đang đo...';
                      if (ram != null) {
                        if (ram['source'] == 'ios_estimated' &&
                            ram['totalGB'] != null) {
                          ramText = '${ram['totalGB']} GB (Ước tính iOS)';
                        } else if (ram['totalBytes'] is num) {
                          final totalGb =
                              (ram['totalBytes'] / (1024 * 1024 * 1024))
                                  .toStringAsFixed(2)
                                  .replaceAll(RegExp(r'\.?0+$'), '');
                          final freeGb = ram['freeBytes'] is num
                              ? (ram['freeBytes'] / (1024 * 1024 * 1024))
                                    .toStringAsFixed(2)
                                    .replaceAll(RegExp(r'\.?0+$'), '')
                              : null;
                          ramText = freeGb != null
                              ? '$totalGb GB (Trống: $freeGb GB)'
                              : '$totalGb GB';
                        }
                      }

                      String romText = 'Đang đo...';
                      if (rom != null) {
                        if (rom['source'] == 'ios_unavailable') {
                          romText = 'Tiêu chuẩn iOS (Sandbox)';
                        } else if (rom['totalBytes'] is num) {
                          final totalGb =
                              (rom['totalBytes'] / (1024 * 1024 * 1024))
                                  .toStringAsFixed(2)
                                  .replaceAll(RegExp(r'\.?0+$'), '');
                          final freeGb = rom['freeBytes'] is num
                              ? (rom['freeBytes'] / (1024 * 1024 * 1024))
                                    .toStringAsFixed(2)
                                    .replaceAll(RegExp(r'\.?0+$'), '')
                              : null;
                          romText = freeGb != null
                              ? '$totalGb GB (Trống: $freeGb GB)'
                              : '$totalGb GB';
                        }
                      }

                      return Column(
                        children: [
                          buildInfoRow(
                            'Hệ điều hành (OS)',
                            controller.osVersion.value.isNotEmpty
                                ? controller.osVersion.value
                                : controller.platform.value,
                          ),
                          SizedBox(height: 8.h),
                          buildInfoRow('Bộ nhớ RAM', ramText),
                          SizedBox(height: 8.h),
                          buildInfoRow('Bộ nhớ trong (ROM)', romText),
                          SizedBox(height: 8.h),
                          buildInfoRow(
                            'Thiết bị',
                            controller.marketingName.value.isNotEmpty
                                ? controller.marketingName.value
                                : controller.modelName.value,
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Device Diagnostics Action Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 8.h,
                ),
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.speed_rounded,
                    color: AppColor.primary,
                    size: 24.r,
                  ),
                ),
                title: Text(
                  'diagnostics_title'.tr,
                  style: AppTextStyle.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'Kiểm định tiêu chuẩn RAM & ROM chi tiết',
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColor.textSecondaryLight,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Get.toNamed(AppRoutes.diagnosticsHome),
              ),
            ),
            SizedBox(height: 20.h),

            // GetX Reactive State Counter Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  children: [
                    Text(
                      'GetX Reactive State',
                      style: AppTextStyle.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Obx(
                      () => Text(
                        '${controller.counter.value}',
                        style: AppTextStyle.displayMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton.icon(
                          onPressed: controller.reset,
                          icon: Icon(Icons.refresh, size: 18.r),
                          label: Text(
                            'cancel'.tr,
                            style: AppTextStyle.labelLarge,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        ElevatedButton.icon(
                          onPressed: controller.increment,
                          icon: Icon(Icons.add, size: 18.r),
                          label: const Text('Increment'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),

            // Environment & Flavor Details Card
            // Card(
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(16.r),
            //   ),
            //   child: Padding(
            //     padding: EdgeInsets.all(16.w),
            //     child: Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         Row(
            //           children: [
            //             Icon(
            //               Icons.info_outline,
            //               color: AppColor.primary,
            //               size: 20.r,
            //             ),
            //             SizedBox(width: 8.w),
            //             Text(
            //               'Environment Details',
            //               style: AppTextStyle.titleSmall.copyWith(
            //                 fontWeight: FontWeight.bold,
            //               ),
            //             ),
            //           ],
            //         ),
            //         Divider(height: 20.h),
            //         buildInfoRow(
            //           'Flavor',
            //           FlavorConfig.instance.flavor.name.toUpperCase(),
            //         ),
            //         SizedBox(height: 8.h),
            //         buildInfoRow('Base URL', FlavorConfig.instance.baseUrl),
            //         SizedBox(height: 8.h),
            //         buildInfoRow(
            //           'Logging',
            //           FlavorConfig.instance.enableLogging.toString(),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  /// Helper row with structured typography for key-value info
}
