import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import 'keys_test_controller.dart';
import 'widgets/key_tile.dart';

/// Màn hình kiểm tra phím vật lý độc lập (KeysTestPage)
/// Hỗ trợ Layer 3: Framework Fallback qua Focus.onKeyEvent và Touch Fallback cho iOS
class KeysTestPage extends GetView<KeysTestController> {
  const KeysTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        // LỚP 3: Framework Fallback nếu EventChannel Native bị chặn
        if (event is KeyDownEvent) {
          if (event.physicalKey == PhysicalKeyboardKey.audioVolumeUp) {
            controller.markVolUp();
            return KeyEventResult.handled;
          } else if (event.physicalKey == PhysicalKeyboardKey.audioVolumeDown) {
            controller.markVolDown();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'keys_test_title'.tr,
            style: AppTextStyle.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'keys_reset_test'.tr,
              onPressed: controller.resetTest,
            ),
          ],
        ),
        body: SafeArea(
          child: Obx(() {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // ==================== 1. CHỌN CHẾ ĐỘ KIỂM TRA ====================
                      _buildModeSelector(),

                      SizedBox(height: 16.h),

                      // ==================== 2. BANNER HƯỚNG DẪN & ĐẾM NGƯỢC ====================
                      _buildInstructionBanner(),

                      SizedBox(height: 20.h),

                      // Tiêu đề danh sách phím
                      Text(
                        'keys_test_subtitle'.tr,
                        style: AppTextStyle.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // ==================== 3. DANH SÁCH THẺ PHÍM VẬT LÝ ====================
                      // Phím Tăng âm lượng (Vol +)
                      KeyTile(
                        title: 'keys_vol_up'.tr,
                        subtitle: 'KeyEvent: KEYCODE_VOLUME_UP (24)',
                        icon: Icons.volume_up_rounded,
                        isPressed: controller.volUp.value,
                        isHighlight: controller.isSequentialMode &&
                            controller.sequentialStep.value == 1,
                        onTap: controller.toggleVolUpManual,
                      ),

                      // Phím Giảm âm lượng (Vol -)
                      KeyTile(
                        title: 'keys_vol_down'.tr,
                        subtitle: 'KeyEvent: KEYCODE_VOLUME_DOWN (25)',
                        icon: Icons.volume_down_rounded,
                        isPressed: controller.volDown.value,
                        isHighlight: controller.isSequentialMode &&
                            controller.sequentialStep.value == 2,
                        onTap: controller.toggleVolDownManual,
                      ),

                      // Phím Nguồn (Power) - Xác nhận thủ công / bấm chạm
                      KeyTile(
                        title: 'keys_power'.tr,
                        subtitle: 'Chạm để xác nhận độ nảy phím nguồn',
                        icon: Icons.power_settings_new_rounded,
                        isPressed: controller.powerConfirmed.value,
                        onTap: controller.togglePowerManualConfirm,
                      ),

                      // Phím Quay lại (Back)
                      KeyTile(
                        title: 'keys_back'.tr,
                        subtitle: 'Phím điều hướng hoặc cử chỉ quay lại',
                        icon: Icons.arrow_back_rounded,
                        isPressed: controller.backPressed.value,
                        onTap: controller.markBack,
                      ),

                      SizedBox(height: 16.h),

                      // Gợi ý cho iOS và Fallback thủ công
                      _buildManualHint(),
                    ],
                  ),
                ),

                // ==================== 4. THANH NÚT HÀNH ĐỘNG DƯỚI CÙNG ====================
                _buildBottomActions(),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Bộ chuyển đổi 2 chế độ: Tự do vs Tuần tự tự động
  Widget _buildModeSelector() {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              title: 'keys_mode_free'.tr,
              isSelected: controller.isFreeMode,
              onTap: () => controller.startVolumeCountdown(seconds: 5),
            ),
          ),
          Expanded(
            child: _buildModeTab(
              title: 'keys_mode_sequential'.tr,
              isSelected: controller.isSequentialMode,
              onTap: controller.startSequentialMode,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: AppTextStyle.labelMedium.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  /// Banner hướng dẫn và đếm ngược thời gian thực
  Widget _buildInstructionBanner() {
    final isDone = controller.areBothVolumeKeysWorking;
    final bannerColor = isDone ? AppColors.success : AppColors.primary;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: bannerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Vòng đếm ngược hoặc icon hoàn thành
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bannerColor.withValues(alpha: 0.15),
            ),
            alignment: Alignment.center,
            child: isDone
                ? Icon(Icons.verified_rounded, color: bannerColor, size: 26.r)
                : (controller.isCountdownActive.value
                    ? Text(
                        '${controller.countdown.value}s',
                        style: AppTextStyle.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: bannerColor,
                        ),
                      )
                    : Icon(Icons.timer_outlined, color: bannerColor, size: 24.r)),
          ),
          SizedBox(width: 14.w),

          // Lời nhắc người dùng
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.instructionText.value,
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: bannerColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  controller.isSequentialMode
                      ? 'keys_auto_next_step'.tr
                      : 'keys_countdown_seconds'.trParams({'seconds': '${controller.countdown.value}'}),
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gợi ý phương án cảm ứng dự phòng
  Widget _buildManualHint() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18.r),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'keys_manual_hint'.tr,
              style: AppTextStyle.caption.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Nút hoàn tất và kiểm tra lại dưới cùng
  Widget _buildBottomActions() {
    final canFinish = controller.isCompleted.value || controller.areBothVolumeKeysWorking;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(Get.context!).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          // Nút đặt lại
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            icon: Icon(Icons.refresh_rounded, size: 18.r),
            label: Text('keys_reset_test'.tr),
            onPressed: controller.resetTest,
          ),
          SizedBox(width: 12.w),

          // Nút hoàn tất kiểm tra
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: canFinish ? AppColors.success : AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: canFinish ? 4 : 0,
              ),
              icon: Icon(
                canFinish ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                size: 20.r,
              ),
              label: Text(
                'keys_finish_test'.tr,
                style: AppTextStyle.button.copyWith(color: Colors.white),
              ),
              onPressed: controller.finishTest,
            ),
          ),
        ],
      ),
    );
  }
}
