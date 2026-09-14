import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

/// Khung xem trước đối chiếu ảnh chụp ra với khung hình camera thực tế
class CameraComparisonView extends StatelessWidget {
  final String imagePath;
  final String cameraTitle;
  final VoidCallback onConfirmMatch;
  final VoidCallback onConfirmMismatch;
  final VoidCallback onRetake;

  const CameraComparisonView({
    super.key,
    required this.imagePath,
    required this.cameraTitle,
    required this.onConfirmMatch,
    required this.onConfirmMismatch,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(imagePath);
    final isExist = file.existsSync();
    final fileSizeKB = isExist ? (file.lengthSync() / 1024).toStringAsFixed(1) : '0';

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiêu đề so khớp
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.compare_rounded,
                  color: AppColors.primary,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'camera_compare_title'.tr,
                      style: AppTextStyle.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$cameraTitle • ${'camera_captured_image'.tr} ($fileSizeKB KB)',
                      style: AppTextStyle.caption.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Khung hiển thị ảnh chụp thực tế
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
                color: Colors.black,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isExist)
                    Image.file(
                      file,
                      fit: BoxFit.cover,
                    )
                  else
                    Center(
                      child: Text(
                        'Không thể đọc file ảnh',
                        style: AppTextStyle.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),

                  // Huy hiệu trạng thái góc trên
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 14.r, color: Colors.greenAccent),
                          SizedBox(width: 4.w),
                          Text(
                            'camera_captured_image'.tr,
                            style: AppTextStyle.caption.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12.h),

          // Lời nhắc kiểm tra
          Text(
            'camera_compare_subtitle'.tr,
            style: AppTextStyle.caption.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 14.h),

          // Nhóm nút hành động
          Row(
            children: [
              // Nút chụp lại
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                icon: Icon(Icons.refresh_rounded, size: 18.r),
                label: Text('camera_retake'.tr),
                onPressed: onRetake,
              ),
              SizedBox(width: 8.w),

              // Nút báo hỏng
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  onPressed: onConfirmMismatch,
                  child: Text(
                    'camera_confirm_mismatch'.tr,
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              SizedBox(width: 8.w),

              // Nút xác nhận ĐẠT
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 2,
                  ),
                  onPressed: onConfirmMatch,
                  child: Text(
                    'camera_confirm_match'.tr,
                    style: AppTextStyle.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
