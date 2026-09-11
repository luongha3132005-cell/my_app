import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

/// Card hiển thị các yêu cầu cần chuẩn bị trước khi kiểm tra (Wi-Fi, Bluetooth, GPS, Rung, Quyền)
class PreCheckRequirementsCard extends StatelessWidget {
  const PreCheckRequirementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.checklist_rounded,
                  color: AppColors.primary,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'pre_check_title'.tr,
                  style: AppTextStyle.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'pre_check_subtitle'.tr,
            style: AppTextStyle.bodySmall.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          SizedBox(height: 12.h),

          _buildRequirementItem(
            icon: Icons.wifi_rounded,
            color: AppColors.info,
            text: 'req_wifi'.tr,
          ),
          _buildRequirementItem(
            icon: Icons.bluetooth_rounded,
            color: AppColors.primary,
            text: 'req_bluetooth'.tr,
          ),
          _buildRequirementItem(
            icon: Icons.location_on_rounded,
            color: AppColors.warning,
            text: 'req_gps'.tr,
          ),
          _buildRequirementItem(
            icon: Icons.vibration_rounded,
            color: AppColors.secondary,
            text: 'req_vibration'.tr,
          ),
          _buildRequirementItem(
            icon: Icons.security_rounded,
            color: AppColors.success,
            text: 'req_permission'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.r, color: color),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: AppTextStyle.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
