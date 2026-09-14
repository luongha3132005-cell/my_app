import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import 'camera_test_controller.dart';
import 'widgets/camera_comparison_view.dart';
import 'widgets/camera_step_indicator.dart';

/// Màn hình kiểm tra phần cứng Camera trước & sau
class CameraTestPage extends GetView<CameraTestController> {
  const CameraTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'camera_test_title'.tr,
          style: AppTextStyle.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút bật/tắt đèn Flash khi đang ở Camera sau
          Obx(() {
            if (controller.currentStep.value == CameraTestStep.backPreview &&
                controller.isCameraInitialized.value) {
              return IconButton(
                icon: Icon(
                  controller.isFlashOn.value
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  color: controller.isFlashOn.value ? Colors.amber : null,
                ),
                tooltip: 'camera_flash_toggle'.tr,
                onPressed: controller.toggleFlash,
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Column(
              children: [
                // 1. Thanh tiến trình 5 bước
                CameraStepIndicator(currentStep: controller.currentStep.value),
                SizedBox(height: 12.h),

                // 2. Nội dung chính theo từng bước
                Expanded(
                  child: _buildStepContent(context),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    // Trường hợp 1: Đã hoàn tất 5 bước kiểm tra -> Hiển thị màn hình tổng kết
    if (controller.isCompleted) {
      return _buildCompletionSummary(context);
    }

    // Trường hợp 2: Bước 2 - So khớp hình chụp Camera sau
    if (controller.currentStep.value == CameraTestStep.backCompare) {
      return CameraComparisonView(
        imagePath: controller.backImagePath.value,
        cameraTitle: 'camera_step_back_preview'.tr,
        onConfirmMatch: () => controller.confirmComparison(true),
        onConfirmMismatch: () => controller.confirmComparison(false),
        onRetake: controller.retakePhoto,
      );
    }

    // Trường hợp 3: Bước 4 - So khớp hình chụp Camera trước
    if (controller.currentStep.value == CameraTestStep.frontCompare) {
      return CameraComparisonView(
        imagePath: controller.frontImagePath.value,
        cameraTitle: 'camera_step_front_preview'.tr,
        onConfirmMatch: () => controller.confirmComparison(true),
        onConfirmMismatch: () => controller.confirmComparison(false),
        onRetake: controller.retakePhoto,
      );
    }

    // Trường hợp 4: Khung ngắm xem trước (Live Preview)
    return _buildLivePreviewView(context);
  }

  /// Khung ngắm xem trước thời gian thực
  Widget _buildLivePreviewView(BuildContext context) {
    if (!controller.isCameraInitialized.value || controller.cameraController == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: 16.h),
            Text(
              'loading'.tr,
              style: AppTextStyle.bodyMedium.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
        ),
      );
    }

    final isBack = controller.currentStep.value == CameraTestStep.backPreview;
    final promptText = isBack ? 'camera_prompt_back'.tr : 'camera_prompt_front'.tr;

    return Column(
      children: [
        // Lời nhắc nhở trên khung ngắm
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
          margin: EdgeInsets.only(bottom: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18.r, color: AppColors.primary),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  promptText,
                  style: AppTextStyle.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Khung ngắm CameraPreview
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              color: Colors.black,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: CameraPreview(controller.cameraController!),
                ),

                // Huy hiệu loại camera góc trên
                Positioned(
                  top: 14.h,
                  left: 14.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isBack ? Icons.camera_rear_rounded : Icons.camera_front_rounded,
                          size: 16.r,
                          color: Colors.white,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isBack ? 'camera_step_back_preview'.tr : 'camera_step_front_preview'.tr,
                          style: AppTextStyle.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 16.h),

        // Nút bấm chụp ảnh lớn ở giữa
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: controller.isTakingPhoto.value ? null : controller.takePhoto,
              child: Container(
                width: 72.r,
                height: 72.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: controller.isTakingPhoto.value
                      ? const CircularProgressIndicator(strokeWidth: 3)
                      : Container(
                          width: 56.r,
                          height: 56.r,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                          ),
                          child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28.r),
                        ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  /// Màn hình tổng kết hoàn tất 5 bước
  Widget _buildCompletionSummary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allPassed = controller.areBothCamerasPassed;

    return ListView(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      physics: const BouncingScrollPhysics(),
      children: [
        // Banner trạng thái tổng
        Container(
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: (allPassed ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: (allPassed ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                allPassed ? Icons.verified_rounded : Icons.error_outline_rounded,
                size: 54.r,
                color: allPassed ? AppColors.success : AppColors.error,
              ),
              SizedBox(height: 10.h),
              Text(
                allPassed ? 'camera_summary_all_good'.tr : 'camera_desc_fail'.tr,
                style: AppTextStyle.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: allPassed ? AppColors.success : AppColors.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        SizedBox(height: 20.h),

        // Chi tiết từng Camera
        _buildResultRow(
          title: 'camera_step_back_preview'.tr,
          isPassed: controller.backCameraPassed.value,
          imagePath: controller.backImagePath.value,
          isDark: isDark,
        ),
        SizedBox(height: 12.h),

        _buildResultRow(
          title: 'camera_step_front_preview'.tr,
          isPassed: controller.frontCameraPassed.value,
          imagePath: controller.frontImagePath.value,
          isDark: isDark,
        ),

        SizedBox(height: 28.h),

        // Nút hoàn tất
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: allPassed ? AppColors.success : AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
            elevation: 2,
          ),
          icon: const Icon(Icons.check_circle_rounded),
          label: Text(
            'keys_finish_test'.tr,
            style: AppTextStyle.button.copyWith(color: Colors.white),
          ),
          onPressed: controller.finishTest,
        ),
      ],
    );
  }

  Widget _buildResultRow({
    required String title,
    required bool isPassed,
    required String imagePath,
    required bool isDark,
  }) {
    final file = File(imagePath);
    final hasImage = file.existsSync();

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isPassed ? AppColors.success : AppColors.error,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Ảnh thumbnail
          Container(
            width: 50.r,
            height: 50.r,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.black12,
            ),
            clipBehavior: Clip.antiAlias,
            child: hasImage
                ? Image.file(file, fit: BoxFit.cover)
                : const Icon(Icons.broken_image_rounded),
          ),
          SizedBox(width: 14.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyle.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2.h),
                Text(
                  isPassed ? 'camera_confirm_match'.tr : 'camera_confirm_mismatch'.tr,
                  style: AppTextStyle.caption.copyWith(
                    color: isPassed ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            isPassed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: isPassed ? AppColors.success : AppColors.error,
            size: 26.r,
          ),
        ],
      ),
    );
  }
}
