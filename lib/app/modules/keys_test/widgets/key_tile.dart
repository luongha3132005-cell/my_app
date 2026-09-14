import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';

/// Tile hiển thị trạng thái từng phím vật lý độc lập
class KeyTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool isPressed;
  final VoidCallback? onTap;
  final bool isHighlight;

  const KeyTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isPressed,
    this.onTap,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeColor = AppColors.success;
    final idleColor = isHighlight ? AppColors.primary : AppColors.textSecondaryLight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: isPressed
            ? activeColor.withValues(alpha: 0.12)
            : (isHighlight
                ? AppColors.primary.withValues(alpha: 0.06)
                : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight)),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isPressed
              ? activeColor
              : (isHighlight
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight)),
          width: isPressed || isHighlight ? 2 : 1,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Icon tròn bên trái
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: isPressed
                        ? activeColor.withValues(alpha: 0.2)
                        : (isHighlight
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05))),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPressed ? Icons.check_circle_rounded : icon,
                    color: isPressed ? activeColor : idleColor,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 14.w),

                // Tiêu đề & phụ đề
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.titleSmall.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPressed
                              ? (isDark ? Colors.white : AppColors.textPrimaryLight)
                              : null,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          subtitle!,
                          style: AppTextStyle.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Badge trạng thái bên phải
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isPressed
                        ? activeColor
                        : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isPressed) ...[
                        Icon(Icons.check, size: 14.r, color: Colors.white),
                        SizedBox(width: 4.w),
                      ],
                      Text(
                        isPressed
                            ? 'keys_status_pressed'.tr
                            : 'keys_status_waiting'.tr,
                        style: AppTextStyle.caption.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isPressed ? Colors.white : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
