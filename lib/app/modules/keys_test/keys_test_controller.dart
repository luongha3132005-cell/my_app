import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'keys_test_repository.dart';

/// Các chế độ kiểm tra phím vật lý
enum KeysTestMode {
  /// Chế độ Tự do: Bấm Vol+ và Vol- bất kỳ lúc nào trong 5 giây
  free,

  /// Chế độ Tuần tự ("Tự động Vol+/-"): Hướng dẫn bấm lần lượt Vol+ rồi Vol-
  sequential,
}

/// Controller quản lý luồng kiểm tra phím vật lý (Layer 2 & State)
class KeysTestController extends GetxController {
  final KeysTestRepository? repository;

  KeysTestController({this.repository});

  // EventChannel kết nối trực tiếp với MainActivity.kt (Layer 1)
  static const EventChannel _keyEventChannel =
      EventChannel('com.fidobox/diagnostics_keyevents');

  StreamSubscription? _keySubscription;
  Timer? _countdownTimer;

  // ==================== REACTIVE STATE (Rx) ====================
  final volUp = false.obs;
  final volDown = false.obs;
  final backPressed = false.obs;
  final powerConfirmed = false.obs;

  final isCompleted = false.obs;
  final testMode = KeysTestMode.free.obs;
  final countdown = 5.obs;
  final isCountdownActive = false.obs;
  final sequentialStep = 0.obs; // 0: idle, 1: chờ Vol+, 2: chờ Vol-, 3: hoàn thành
  final instructionText = ''.obs;

  // Getters
  bool get areBothVolumeKeysWorking => volUp.value && volDown.value;
  bool get isFreeMode => testMode.value == KeysTestMode.free;
  bool get isSequentialMode => testMode.value == KeysTestMode.sequential;

  @override
  void onInit() {
    super.onInit();
    _listenNativeKeyEvents();
    // Mặc định khởi chạy chế độ Tự do với 5 giây đếm ngược
    startVolumeCountdown(seconds: 5);
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    _keySubscription?.cancel();
    super.onClose();
  }

  // ==================== LỚP 2: NATIVE EVENT CHANNEL LISTENER ====================
  void _listenNativeKeyEvents() {
    try {
      _keySubscription = _keyEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          final int? keyCode = (event is int)
              ? event
              : (event is Map ? event['keyCode'] as int? : null);

          if (keyCode == 24) {
            markVolUp();
          } else if (keyCode == 25) {
            markVolDown();
          } else if (keyCode == 4) {
            markBack();
          }
        },
        onError: (dynamic error) {
          debugPrint('Key event channel stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('Error subscribing to key events: $e');
    }
  }

  // ==================== CƠ CHẾ 1: CHẾ ĐỘ TỰ DO (ĐẾM NGƯỢC 5 GIÂY) ====================
  void startVolumeCountdown({int seconds = 5}) {
    _countdownTimer?.cancel();
    testMode.value = KeysTestMode.free;
    sequentialStep.value = 0;
    countdown.value = seconds;
    isCountdownActive.value = true;
    instructionText.value = 'keys_prompt_free'.tr;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        countdown.value = 0;
        isCountdownActive.value = false;
        timer.cancel();
        // Kiểm tra xem đã đủ 2 phím chưa
        if (areBothVolumeKeysWorking) {
          isCompleted.value = true;
          instructionText.value = 'keys_prompt_completed'.tr;
        }
      }
    });
  }

  // ==================== CƠ CHẾ 2: CHẾ ĐỘ TUẦN TỰ ("TỰ ĐỘNG VOL+/-") ====================
  void startSequentialMode() {
    _countdownTimer?.cancel();
    testMode.value = KeysTestMode.sequential;
    volUp.value = false;
    volDown.value = false;
    isCompleted.value = false;

    _startStep1VolUp();
  }

  void _startStep1VolUp() {
    sequentialStep.value = 1;
    instructionText.value = 'keys_prompt_press_vol_up'.tr;
    countdown.value = 5;
    isCountdownActive.value = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        countdown.value = 0;
        isCountdownActive.value = false;
        timer.cancel();
      }
    });
  }

  void _startStep2VolDown() {
    sequentialStep.value = 2;
    instructionText.value = 'keys_prompt_press_vol_down'.tr;
    countdown.value = 5;
    isCountdownActive.value = true;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown.value > 1) {
        countdown.value--;
      } else {
        countdown.value = 0;
        isCountdownActive.value = false;
        timer.cancel();
      }
    });
  }

  // ==================== HÀM ĐÁNH DẤU PHÍM (MARKERS) ====================

  /// Đánh dấu phím Tăng âm lượng được bấm (Từ Native, Framework Focus hoặc Tap)
  void markVolUp() {
    if (!volUp.value) {
      volUp.value = true;
      HapticFeedback.mediumImpact();
    }

    if (isSequentialMode && sequentialStep.value == 1) {
      _countdownTimer?.cancel();
      // Chờ hiệu ứng chuyển bước mượt mà
      Future.delayed(const Duration(milliseconds: 350), () {
        _startStep2VolDown();
      });
    } else if (isFreeMode) {
      _checkFreeModeCompletion();
    }
  }

  /// Đánh dấu phím Giảm âm lượng được bấm (Từ Native, Framework Focus hoặc Tap)
  void markVolDown() {
    if (!volDown.value) {
      volDown.value = true;
      HapticFeedback.mediumImpact();
    }

    if (isSequentialMode && sequentialStep.value == 2) {
      _countdownTimer?.cancel();
      sequentialStep.value = 3;
      isCompleted.value = true;
      isCountdownActive.value = false;
      instructionText.value = 'keys_prompt_completed'.tr;
    } else if (isFreeMode) {
      _checkFreeModeCompletion();
    }
  }

  /// Đánh dấu phím Quay lại (Back)
  void markBack() {
    if (!backPressed.value) {
      backPressed.value = true;
      HapticFeedback.lightImpact();
    }
  }

  /// Bật/tắt xác nhận phím Nguồn thủ công
  void togglePowerManualConfirm() {
    powerConfirmed.value = !powerConfirmed.value;
    HapticFeedback.selectionClick();
  }

  void _checkFreeModeCompletion() {
    if (areBothVolumeKeysWorking) {
      _countdownTimer?.cancel();
      isCountdownActive.value = false;
      isCompleted.value = true;
      instructionText.value = 'keys_prompt_completed'.tr;
    }
  }

  // ==================== TƯƠNG TÁC THỦ CÔNG (iOS / MANUAL FALLBACK) ====================
  void toggleVolUpManual() => markVolUp();
  void toggleVolDownManual() => markVolDown();

  /// Đặt lại toàn bộ trạng thái bài kiểm tra
  void resetTest() {
    _countdownTimer?.cancel();
    volUp.value = false;
    volDown.value = false;
    backPressed.value = false;
    powerConfirmed.value = false;
    isCompleted.value = false;

    if (isSequentialMode) {
      startSequentialMode();
    } else {
      startVolumeCountdown(seconds: 5);
    }
  }

  /// Hoàn tất bài kiểm tra và trả về dữ liệu kết quả chuẩn
  void finishTest() {
    final payload = {
      'userConfirm': areBothVolumeKeysWorking,
      'volumeUp': volUp.value,
      'volumeDown': volDown.value,
      'back': backPressed.value,
      'powerManualConfirm': powerConfirmed.value,
    };

    // Gửi kết quả qua repository nếu có
    repository?.submitKeysTestResult(payload);

    Get.back(result: payload);
  }
}
