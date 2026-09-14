import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_style.dart';
import 'waveform_painter.dart';

/// 3 giai đoạn của bài kiểm tra Microphone
enum MicTestPhase {
  recording,
  playing,
  confirming,
}

/// Hộp thoại tương tác kiểm tra Microphone (Thu âm 5s -> Phát lại -> Xác nhận)
class MicTestDialog extends StatefulWidget {
  const MicTestDialog({super.key});

  @override
  State<MicTestDialog> createState() => _MicTestDialogState();
}

class _MicTestDialogState extends State<MicTestDialog> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();

  MicTestPhase _phase = MicTestPhase.recording;
  String? _recordingPath;
  StreamSubscription<Amplitude>? _amplitudeSub;
  Timer? _countdownTimer;

  int _countdown = 5;
  final List<double> _amplitudeHistory = [];
  double _maxAmplitudeDb = -160.0;
  bool _hasDetectedSound = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startMicTest();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _amplitudeSub?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  Future<void> _cleanupTempFile() async {
    if (_recordingPath != null) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting temp recording: $e');
      }
    }
  }

  /// Khởi động quy trình: xin quyền kép và bắt đầu ghi âm
  Future<void> _startMicTest() async {
    try {
      // 1. Xin quyền Microphone từ hệ điều hành qua permission_handler
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage = 'mic_permission_denied'.tr;
        });
        return;
      }

      // 2. Kiểm tra lại một lần nữa với bộ thu âm AudioRecorder
      final hasPerm = await _audioRecorder.hasPermission();
      if (!hasPerm) {
        setState(() {
          _errorMessage = 'mic_hardware_permission_denied'.tr;
        });
        return;
      }

      // 3. Chuẩn bị đường dẫn file tạm .m4a
      final tempDir = await getTemporaryDirectory();
      _recordingPath = '${tempDir.path}/mic_test_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 4. Bắt đầu thu âm chuẩn AAC LC
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      // 5. Lắng nghe biên độ âm thanh thời gian thực (Real-time Amplitude)
      _amplitudeSub = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        if (!mounted) return;
        final currentDb = amp.current;
        if (currentDb > _maxAmplitudeDb) {
          _maxAmplitudeDb = currentDb;
        }

        // Phát hiện âm thanh nếu lớn hơn ngưỡng môi trường (-42 dBFS)
        if (currentDb > -42.0) {
          _hasDetectedSound = true;
        }

        // Chuẩn hóa -60dBFS..0dBFS sang khoảng 0.05..1.0
        final normalized = ((currentDb + 60) / 60).clamp(0.08, 1.0);
        setState(() {
          _amplitudeHistory.add(normalized);
          if (_amplitudeHistory.length > 50) {
            _amplitudeHistory.removeAt(0);
          }
        });
      });

      // 6. Đếm ngược 5 giây
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          _countdown--;
        });
        if (_countdown <= 0) {
          timer.cancel();
          _stopRecordingAndPlay();
        }
      });
    } catch (e) {
      debugPrint('Error starting microphone test: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  /// Dừng thu âm và tự động phát lại đoạn âm thanh vừa thu
  Future<void> _stopRecordingAndPlay() async {
    await _amplitudeSub?.cancel();
    try {
      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      if (!mounted) return;
      setState(() {
        _phase = MicTestPhase.playing;
      });

      if (_recordingPath != null && await File(_recordingPath!).exists()) {
        await _audioPlayer.play(DeviceFileSource(_recordingPath!));

        // Khi phát xong thì chuyển sang bước xác nhận
        _audioPlayer.onPlayerComplete.listen((_) {
          if (!mounted) return;
          setState(() {
            _phase = MicTestPhase.confirming;
          });
        });
      } else {
        setState(() {
          _phase = MicTestPhase.confirming;
        });
      }
    } catch (e) {
      debugPrint('Error in audio playback: $e');
      if (mounted) {
        setState(() {
          _phase = MicTestPhase.confirming;
        });
      }
    }
  }

  /// Hoàn tất bài test và trả kết quả cho caller
  void _finishTest(bool userConfirm) {
    Get.back(result: {
      'permission': true,
      'recorded': true,
      'hasDetectedSound': _hasDetectedSound,
      'maxAmplitudeDb': _maxAmplitudeDb,
      'userConfirm': userConfirm,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      backgroundColor: AppColors.cardLight,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Icon & Title
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: AppColors.error,
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mic_test_dialog_title'.tr,
                        style: AppTextStyle.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _getPhaseSubtitle(),
                        style: AppTextStyle.bodySmall.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // Main Phase Content
            if (_errorMessage != null) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyle.bodySmall.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: () {
                  Get.back(result: {
                    'permission': false,
                    'recorded': false,
                    'hasDetectedSound': false,
                    'userConfirm': false,
                  });
                },
                child: Text('close'.tr),
              ),
            ] else ...[
              // Khung sóng âm (Visualizer Container)
              Container(
                height: 100.h,
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.borderLight,
                  ),
                ),
                child: _phase == MicTestPhase.recording
                    ? CustomPaint(
                        painter: WaveformPainter(
                          amplitudeHistory: _amplitudeHistory,
                          barColor: AppColors.error,
                        ),
                      )
                    : Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _phase == MicTestPhase.playing
                                  ? Icons.volume_up_rounded
                                  : Icons.check_circle_outline_rounded,
                              size: 28.r,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _phase == MicTestPhase.playing
                                  ? 'mic_playing_audio'.tr
                                  : 'mic_confirm_hint'.tr,
                              style: AppTextStyle.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              SizedBox(height: 16.h),

              // Trạng thái đếm ngược hoặc hướng dẫn
              if (_phase == MicTestPhase.recording) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14.r,
                      height: 14.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'mic_countdown'.trParams({'seconds': '$_countdown'}),
                      style: AppTextStyle.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ],

              if (_phase == MicTestPhase.playing) ...[
                Text(
                  'mic_listen_carefully'.tr,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              if (_phase == MicTestPhase.confirming) ...[
                Text(
                  'mic_ask_hear'.tr,
                  style: AppTextStyle.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _finishTest(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        icon: const Icon(Icons.close_rounded),
                        label: Text('mic_cannot_hear'.tr),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _finishTest(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: AppColors.white,
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        icon: const Icon(Icons.check_rounded),
                        label: Text('mic_hear_clearly'.tr),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _getPhaseSubtitle() {
    switch (_phase) {
      case MicTestPhase.recording:
        return 'mic_speak_prompt'.tr;
      case MicTestPhase.playing:
        return 'mic_playing_prompt'.tr;
      case MicTestPhase.confirming:
        return 'mic_confirm_prompt'.tr;
    }
  }
}
