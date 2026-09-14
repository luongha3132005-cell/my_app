import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'camera_test_repository.dart';

/// Các bước trong quy trình kiểm tra camera
enum CameraTestStep {
  backPreview, // Bước 1: Khung ngắm Camera sau + Đèn Flash / Focus
  backCompare, // Bước 2: So khớp hình chụp Cam sau với khung ngắm
  frontPreview, // Bước 3: Khung ngắm Camera trước
  frontCompare, // Bước 4: So khớp hình chụp Cam trước với khung ngắm
  completed, // Bước 5: Hoàn tất kiểm tra
}

/// Controller quản lý luồng kiểm tra camera trước và sau
class CameraTestController extends GetxController {
  final CameraTestRepository? repository;

  CameraTestController({this.repository});

  // ==================== REACTIVE STATE (Rx) ====================
  final currentStep = CameraTestStep.backPreview.obs;
  final isCameraInitialized = false.obs;
  final isTakingPhoto = false.obs;
  final isFlashOn = false.obs;
  final errorMessage = ''.obs;

  // Đường dẫn ảnh chụp tạm thời
  final backImagePath = ''.obs;
  final frontImagePath = ''.obs;

  // Kết quả thẩm định
  final backCameraPassed = false.obs;
  final frontCameraPassed = false.obs;
  final flashPassed = false.obs;

  // Quản lý phần cứng Camera
  List<CameraDescription> cameras = [];
  CameraDescription? backCameraDesc;
  CameraDescription? frontCameraDesc;
  CameraController? cameraController;

  bool get isCompleted => currentStep.value == CameraTestStep.completed;
  bool get areBothCamerasPassed => backCameraPassed.value && frontCameraPassed.value;

  @override
  void onInit() {
    super.onInit();
    initCameras();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  /// Khởi tạo và phân loại camera trước & sau
  Future<void> initCameras() async {
    try {
      isCameraInitialized.value = false;

      // 1. Nhận danh sách camera từ arguments hoặc availableCameras
      final args = Get.arguments;
      if (args is List<CameraDescription> && args.isNotEmpty) {
        cameras = args;
      } else {
        cameras = await availableCameras();
      }

      if (cameras.isEmpty) {
        errorMessage.value = 'camera_no_cameras_found'.tr;
        return;
      }

      // 2. Phân loại camera trước và sau
      backCameraDesc = cameras.firstWhereOrNull(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      frontCameraDesc = cameras.firstWhereOrNull(
        (c) => c.lensDirection == CameraLensDirection.front,
      );

      // Nếu không có camera sau thì lấy camera đầu tiên khả dụng
      final initialCamera = backCameraDesc ?? cameras.first;
      await _setupCamera(initialCamera);
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      errorMessage.value = e.toString();
    }
  }

  /// Cấu hình CameraController an toàn
  Future<void> _setupCamera(CameraDescription desc) async {
    try {
      isCameraInitialized.value = false;
      await cameraController?.dispose();

      cameraController = CameraController(
        desc,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      isFlashOn.value = false;
    } catch (e) {
      debugPrint('Error setting up camera controller: $e');
      errorMessage.value = e.toString();
    }
  }

  /// Bấm chụp ảnh và lưu file tạm thời
  Future<void> takePhoto() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;
    if (isTakingPhoto.value) return;

    try {
      isTakingPhoto.value = true;
      HapticFeedback.mediumImpact();

      final XFile photo = await cameraController!.takePicture();
      final file = File(photo.path);

      // Kiểm tra tính toàn vẹn của file ảnh (tồn tại và dung lượng > 0)
      if (!file.existsSync() || file.lengthSync() <= 0) {
        throw Exception('Ảnh chụp bị rỗng (0 bytes) hoặc không thể đọc file');
      }

      if (currentStep.value == CameraTestStep.backPreview) {
        backImagePath.value = photo.path;
        currentStep.value = CameraTestStep.backCompare;
      } else if (currentStep.value == CameraTestStep.frontPreview) {
        frontImagePath.value = photo.path;
        currentStep.value = CameraTestStep.frontCompare;
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      Get.snackbar(
        'error_title'.tr,
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isTakingPhoto.value = false;
    }
  }

  /// Xác nhận so khớp ảnh chụp với khung hình camera thực tế
  Future<void> confirmComparison(bool isMatched) async {
    HapticFeedback.selectionClick();

    if (currentStep.value == CameraTestStep.backCompare) {
      backCameraPassed.value = isMatched;

      if (isMatched) {
        // Chuyển sang kiểm tra Camera trước
        if (frontCameraDesc != null) {
          currentStep.value = CameraTestStep.frontPreview;
          await _setupCamera(frontCameraDesc!);
        } else {
          // Máy chỉ có 1 camera
          frontCameraPassed.value = true;
          currentStep.value = CameraTestStep.completed;
        }
      } else {
        // Camera sau không đạt -> vẫn cho phép tiếp tục hoặc hoàn tất
        if (frontCameraDesc != null) {
          currentStep.value = CameraTestStep.frontPreview;
          await _setupCamera(frontCameraDesc!);
        } else {
          currentStep.value = CameraTestStep.completed;
        }
      }
    } else if (currentStep.value == CameraTestStep.frontCompare) {
      frontCameraPassed.value = isMatched;
      currentStep.value = CameraTestStep.completed;
    }
  }

  /// Chụp lại ảnh nếu người dùng muốn góc khác
  void retakePhoto() {
    if (currentStep.value == CameraTestStep.backCompare) {
      currentStep.value = CameraTestStep.backPreview;
    } else if (currentStep.value == CameraTestStep.frontCompare) {
      currentStep.value = CameraTestStep.frontPreview;
    }
  }

  /// Bật / Tắt đèn Flash khi ở Camera sau
  Future<void> toggleFlash() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    try {
      isFlashOn.value = !isFlashOn.value;
      await cameraController!.setFlashMode(
        isFlashOn.value ? FlashMode.torch : FlashMode.off,
      );
      if (isFlashOn.value) {
        flashPassed.value = true;
      }
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Flash not supported or error: $e');
    }
  }

  /// Hoàn tất thẩm định và trả về kết quả payload
  void finishTest() {
    final payload = {
      'permission': true,
      'backCamera': backCameraPassed.value,
      'frontCamera': frontCameraPassed.value,
      'flash': flashPassed.value,
      'backImagePath': backImagePath.value,
      'frontImagePath': frontImagePath.value,
      'userConfirm': areBothCamerasPassed,
    };

    // Gửi kết quả qua repository nếu có
    repository?.submitCameraTestResult(payload);

    Get.back(result: payload);
  }
}
