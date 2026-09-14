import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Painter vẽ sóng âm thời gian thực (Waveform Audio Visualizer)
class WaveformPainter extends CustomPainter {
  final List<double> amplitudeHistory;
  final Color barColor;

  const WaveformPainter({
    required this.amplitudeHistory,
    this.barColor = AppColors.primary,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudeHistory.isEmpty) return;

    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final centerY = size.height / 2;
    const barWidth = 3.5;
    const spacing = 2.5;
    final totalBars = (size.width / (barWidth + spacing)).floor();

    // Lấy các giá trị gần nhất để vừa vặn với chiều ngang hiển thị
    final startIndex = (amplitudeHistory.length - totalBars).clamp(0, amplitudeHistory.length);
    final visibleAmplitudes = amplitudeHistory.sublist(startIndex);

    for (var i = 0; i < visibleAmplitudes.length; i++) {
      final x = i * (barWidth + spacing);
      final rawAmp = visibleAmplitudes[i];

      // Chuẩn hóa chiều cao cột sóng âm (tối thiểu 4px, tối đa 90% chiều cao khung)
      final normalizedHeight = (rawAmp * (size.height * 0.85)).clamp(4.0, size.height * 0.9);
      final top = centerY - (normalizedHeight / 2);
      final bottom = centerY + (normalizedHeight / 2);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, top, x + barWidth, bottom),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return true; // Luôn cập nhật khi danh sách biên độ thay đổi
  }
}
