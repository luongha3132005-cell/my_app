import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:my_app/app/core/theme/app_colors.dart';
import 'package:my_app/app/core/theme/app_text_style.dart';

Widget buildInfoRow(String label, String value) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: AppTextStyle.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: AppTextStyle.bodyMedium.copyWith(
            color: AppColor.textSecondaryLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
