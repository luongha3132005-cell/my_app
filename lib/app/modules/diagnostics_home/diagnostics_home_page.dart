import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import '../../data/services/rule_evaluator.dart';
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
          style: AppTextStyle.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'refresh'.tr,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: controller.runDiagnostics,
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

                SizedBox(height: 12.h),

                // 2. Hardware Tests Status Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'hardware_evaluation'.tr,
                        style: AppTextStyle.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // RAM Test Card
                      _buildEvalCard(
                        title: 'RAM (Bộ nhớ truy xuất ngẫu nhiên)',
                        description: _formatRamDetails(controller.ramInfo),
                        result: controller.ramEvalResult.value,
                        icon: Icons.memory_rounded,
                      ),

                      SizedBox(height: 10.h),

                      // ROM Test Card
                      _buildEvalCard(
                        title: 'ROM (Bộ nhớ lưu trữ thiết bị)',
                        description: _formatRomDetails(controller.romInfo),
                        result: controller.romEvalResult.value,
                        icon: Icons.storage_rounded,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                // 3. Action Button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: ElevatedButton.icon(
                    onPressed: controller.isLoading.value
                        ? null
                        : controller.runDiagnostics,
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

  Widget _buildEvalCard({
    required String title,
    required String description,
    required EvalResult? result,
    required IconData icon,
  }) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (result) {
      case EvalResult.pass:
        statusColor = AppColors.success;
        statusText = 'Đạt chuẩn';
        statusIcon = Icons.check_circle_rounded;
        break;
      case EvalResult.fail:
        statusColor = AppColors.error;
        statusText = 'Không đạt';
        statusIcon = Icons.cancel_rounded;
        break;
      case EvalResult.skip:
        statusColor = AppColors.info;
        statusText = 'Miễn kiểm tra (iOS)';
        statusIcon = Icons.info_rounded;
        break;
      case EvalResult.warning:
        statusColor = AppColors.warning;
        statusText = 'Cảnh báo';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case null:
        statusColor = AppColors.textSecondaryLight;
        statusText = 'Đang kiểm tra...';
        statusIcon = Icons.hourglass_top_rounded;
        break;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: statusColor, size: 24.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyle.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    description,
                    style: AppTextStyle.bodySmall.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(statusIcon, color: statusColor, size: 20.r),
                SizedBox(height: 2.h),
                Text(
                  statusText,
                  style: AppTextStyle.caption.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatRamDetails(Map<String, dynamic>? ram) {
    if (ram == null) return 'Chưa đo đạc';
    final total = ram['totalBytes'];
    final free = ram['freeBytes'];
    final totalGB = ram['totalGB'];
    final source = ram['source'];

    if (source == 'ios_estimated' && totalGB != null) {
      return 'Ước tính: $totalGB GB (iOS Architecture)';
    }

    if (total is num) {
      final totalGb = (total / (1024 * 1024 * 1024))
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.?0+$'), '');
      final freeGb = free is num
          ? (free / (1024 * 1024 * 1024))
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'\.?0+$'), '')
          : null;
      return freeGb != null
          ? 'Tổng: $totalGb GB • Khả dụng: $freeGb GB'
          : 'Tổng: $totalGb GB';
    }

    return 'Nguồn: $source';
  }

  String _formatRomDetails(Map<String, dynamic>? rom) {
    if (rom == null) return 'Chưa đo đạc';
    final total = rom['totalBytes'];
    final free = rom['freeBytes'];
    final source = rom['source'];

    if (source == 'ios_unavailable') {
      return 'Bảo mật sandbox Apple (Bộ nhớ tiêu chuẩn)';
    }

    if (total is num) {
      final totalGb = (total / (1024 * 1024 * 1024))
          .toStringAsFixed(2)
          .replaceAll(RegExp(r'\.?0+$'), '');
      final freeGb = free is num
          ? (free / (1024 * 1024 * 1024))
              .toStringAsFixed(2)
              .replaceAll(RegExp(r'\.?0+$'), '')
          : null;
      return freeGb != null
          ? 'Tổng: $totalGb GB • Trống: $freeGb GB'
          : 'Tổng: $totalGb GB';
    }

    return 'Nguồn: $source';
  }
}
