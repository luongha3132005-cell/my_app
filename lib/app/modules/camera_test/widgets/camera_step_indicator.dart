import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import '../camera_test_controller.dart';

/// Thanh hiển thị 5 bước kiểm tra camera trực quan
class CameraStepIndicator extends StatelessWidget {
  final CameraTestStep currentStep;

  const CameraStepIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final steps = [
      {'key': CameraTestStep.backPreview, 'title': 'camera_step_back_preview'.tr},
      {'key': CameraTestStep.backCompare, 'title': 'camera_step_back_compare'.tr},
      {'key': CameraTestStep.frontPreview, 'title': 'camera_step_front_preview'.tr},
      {'key': CameraTestStep.frontCompare, 'title': 'camera_step_front_compare'.tr},
      {'key': CameraTestStep.completed, 'title': 'camera_step_finish'.tr},
    ];

    final currentIndex = steps.indexWhere((s) => s['key'] == currentStep);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isPassed = index < currentIndex;
          final isCurrent = index == currentIndex;

          final Color circleColor = isPassed
              ? AppColors.success
              : (isCurrent ? AppColors.primary : Colors.grey.shade400);

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22.r,
                        height: 22.r,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: isPassed
                            ? Icon(Icons.check, size: 14.r, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: AppTextStyle.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        steps[index]['title'] as String,
                        style: AppTextStyle.caption.copyWith(
                          fontSize: 10.sp,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCurrent
                              ? AppColors.primary
                              : (isPassed ? AppColors.success : AppColors.textSecondaryLight),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 12.w,
                    height: 2.h,
                    margin: EdgeInsets.only(bottom: 14.h),
                    color: index < currentIndex ? AppColors.success : Colors.grey.shade300,
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
