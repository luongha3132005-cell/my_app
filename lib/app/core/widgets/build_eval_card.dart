import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/app/core/theme/app_colors.dart';
import 'package:my_app/app/core/theme/app_text_style.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';

/// Card hiển thị kết quả đánh giá phần cứng (RAM, ROM...) dùng chung
Widget buildEvalCard({
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
