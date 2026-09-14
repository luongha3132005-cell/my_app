import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_style.dart';
import '../../core/widgets/build_eval_card.dart';
import 'funtion_check_controller.dart';
import 'widgets/function_check_action_buttons.dart';
import 'widgets/pre_check_requirements_card.dart';

/// Giao diện màn hình kiểm tra riêng biệt: Nhắc nhở yêu cầu cần thiết & hiển thị 6 bài kiểm tra
class FuntionCheckPage extends GetView<FuntionCheckController> {
  const FuntionCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'function_check_title'.tr,
          style: AppTextStyle.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Nút chuyển đổi ngôn ngữ Anh - Việt
          IconButton(
            tooltip: 'language'.tr,
            icon: Icon(Icons.language, size: 24.r),
            onPressed: controller.toggleLanguage,
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final content = ListView(
            physics: controller.hasStartedCheck.value
                ? const AlwaysScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            children: [
                // ==================== 1. KHỐI NHẮC NHỞ & YÊU CẦU CẦN THIẾT ====================
                const PreCheckRequirementsCard(),

                SizedBox(height: 16.h),

                // ==================== 2. NÚT "BẮT ĐẦU KIỂM TRA" DƯỚI YÊU CẦU ====================
                if (!controller.hasStartedCheck.value) ...[
                  StartDiagnosticsButton(
                    onPressed: controller.startDiagnostics,
                  ),
                ],

                // ==================== 3. KHỐI KẾT QUẢ 6 BÀI KIỂM ĐỊNH ====================
                if (controller.hasStartedCheck.value) ...[
                  // Banner tiến trình đo đạc
                  if (controller.isLoading.value) ...[
                    Container(
                      padding: EdgeInsets.all(12.r),
                      margin: EdgeInsets.only(bottom: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'testing_in_progress'.trParams({'step': controller.currentStepTitle.value}),
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tiêu đề kết quả
                  Text(
                    'hardware_evaluation'.tr,
                    style: AppTextStyle.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // 1. RAM Card
                  buildEvalCard(
                    title: 'ram_test'.tr,
                    description: controller.ramInfo.value?['totalBytes'] != null
                        ? '${(controller.ramInfo.value!['totalBytes'] / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                        : (controller.ramInfo.value?['totalGB'] != null
                            ? '${controller.ramInfo.value!['totalGB']} GB'
                            : 'loading'.tr),
                    result: controller.ramEvalResult.value,
                    icon: Icons.memory_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 2. ROM Card
                  buildEvalCard(
                    title: 'rom_test'.tr,
                    description: controller.romInfo.value?['totalBytes'] != null
                        ? '${(controller.romInfo.value!['totalBytes'] / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB'
                        : (GetPlatform.isIOS ? 'ios_sandbox_rom'.tr : 'loading'.tr),
                    result: controller.romEvalResult.value,
                    icon: Icons.storage_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 3. Wi-Fi Card
                  buildEvalCard(
                    title: 'wifi_test'.tr,
                    description: controller.wifiInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isWifiEnabled
                            ? 'wifi_desc_disabled'.tr
                            : (controller.isWifiConnected
                                ? 'wifi_desc_connected'.trParams({'ssid': controller.wifiSsid ?? 'Đã kết nối'})
                                : 'wifi_desc_disconnected'.tr)),
                    result: controller.wifiEvalResult.value,
                    icon: Icons.wifi_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 4. Bluetooth Card
                  buildEvalCard(
                    title: 'bluetooth_test'.tr,
                    description: controller.bluetoothInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isBluetoothEnabled
                            ? 'bluetooth_desc_disabled'.tr
                            : (!controller.hasBluetoothPermission.value
                                ? 'bluetooth_desc_no_perm'.tr
                                : 'bluetooth_desc_scanned'.trParams({'count': '${controller.bluetoothDevicesCount}'}))),
                    result: controller.btEvalResult.value,
                    icon: Icons.bluetooth_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 5. GPS Card
                  buildEvalCard(
                    title: 'gps_test'.tr,
                    description: controller.gpsInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isGpsServiceOn
                            ? 'gps_desc_disabled'.tr
                            : (controller.gpsAccuracy == null
                                ? 'gps_desc_no_accuracy'.tr
                                : 'gps_desc_accuracy'.trParams({'accuracy': controller.gpsAccuracy!.toStringAsFixed(1)}))),
                    result: controller.gpsEvalResult.value,
                    icon: Icons.location_on_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 6. Vibration Card
                  buildEvalCard(
                    title: 'vibrate_test'.tr,
                    description: controller.vibrateInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isVibrateSupported
                            ? 'vibrate_desc_unsupported'.tr
                            : (controller.isVibrateConfirmed
                                ? 'vibrate_desc_pass'.tr
                                : 'vibrate_desc_fail'.tr)),
                    result: controller.vibrateEvalResult.value,
                    icon: Icons.vibration_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 7. Biometrics Card (Cảm biến sinh trắc học)
                  buildEvalCard(
                    title: 'biometric_test'.tr,
                    description: controller.bioInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isBiometricSupported
                            ? 'bio_desc_unsupported'.tr
                            : (!controller.canCheckBiometrics
                                ? 'bio_desc_not_enrolled'.tr
                                : 'bio_desc_available'.tr)),
                    result: controller.bioEvalResult.value,
                    icon: Icons.fingerprint_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 8. Microphone Card (Thu âm & Micro)
                  buildEvalCard(
                    title: 'mic_test'.tr,
                    description: controller.micInfo.value == null
                        ? 'loading'.tr
                        : (!controller.isMicPermGranted
                            ? 'mic_desc_no_perm'.tr
                            : (controller.isMicConfirmed
                                ? 'mic_desc_pass'.tr
                                : 'mic_desc_fail'.tr)),
                    result: controller.micEvalResult.value,
                    icon: Icons.mic_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 9. Physical Keys Card (Phím vật lý: Âm lượng & Nguồn)
                  buildEvalCard(
                    title: 'keys_test'.tr,
                    description: controller.keysInfo.value == null
                        ? 'keys_desc_pending'.tr
                        : (controller.isVolUpOk && controller.isVolDownOk
                            ? 'keys_desc_pass'.tr
                            : 'keys_desc_fail'.tr),
                    result: controller.keysEvalResult.value,
                    icon: Icons.tune_rounded,
                  ),
                  SizedBox(height: 8.h),

                  // 10. Camera Card (Camera trước & sau)
                  buildEvalCard(
                    title: 'camera_test'.tr,
                    description: controller.cameraInfo.value == null
                        ? 'camera_desc_pending'.tr
                        : (controller.cameraInfo.value?['permission'] == false
                            ? 'camera_desc_no_perm'.tr
                            : (controller.isBackCameraOk && controller.isFrontCameraOk
                                ? 'camera_desc_pass'.tr
                                : 'camera_desc_fail'.tr)),
                    result: controller.cameraEvalResult.value,
                    icon: Icons.camera_alt_rounded,
                  ),

                  SizedBox(height: 24.h),

                  // Nút kiểm tra lại toàn bộ
                  RecheckDiagnosticsButton(
                    isLoading: controller.isLoading.value,
                    onPressed: controller.runFunctionCheck,
                  ),
                ],

                SizedBox(height: 32.h),
              ],
            );

            if (!controller.hasStartedCheck.value) {
              return content;
            }

            return RefreshIndicator(
              onRefresh: controller.runFunctionCheck,
              child: content,
            );
          }),
        ),
      );
  }
}
