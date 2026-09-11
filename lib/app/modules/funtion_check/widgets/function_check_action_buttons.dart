import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

/// Nút "Bắt đầu kiểm tra" nằm dưới khối yêu cầu chuẩn bị
class StartDiagnosticsButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const StartDiagnosticsButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        backgroundColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      icon: Icon(Icons.play_arrow_rounded, size: 24.r, color: AppColors.white),
      label: Text(
        'start_diagnostics_now'.tr,
        style: AppTextStyle.button.copyWith(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// Nút "Kiểm tra lại toàn bộ" hiển thị phía dưới danh sách kết quả 6 bài test
class RecheckDiagnosticsButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const RecheckDiagnosticsButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      icon: isLoading
          ? SizedBox(
              width: 18.r,
              height: 18.r,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(
        isLoading ? 'loading'.tr : 'recheck_all'.tr,
        style: AppTextStyle.button,
      ),
    );
  }
}
