import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

/// Nút lớn "Bắt đầu kiểm tra chức năng" trên trang DiagnosticsHomePage
class StartFunctionCheckButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const StartFunctionCheckButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        icon: isLoading
            ? SizedBox(
                width: 20.r,
                height: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : const Icon(Icons.speed_rounded),
        label: Text(
          'start_function_check'.tr,
          style: AppTextStyle.button.copyWith(fontSize: 16.sp),
        ),
      ),
    );
  }
}
