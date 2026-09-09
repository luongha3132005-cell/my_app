/// Kết quả đánh giá kiểm định phần cứng
enum EvalResult {
  pass,
  fail,
  skip,
  warning;

  bool get isPass => this == EvalResult.pass;
  bool get isFail => this == EvalResult.fail;
  bool get isSkip => this == EvalResult.skip;
  bool get isWarning => this == EvalResult.warning;
}

/// Rule Evaluator - Kiểm tra & đánh giá thông số phần cứng theo tiêu chuẩn
class RuleEvaluator {
  const RuleEvaluator();

  /// Đánh giá kết quả kiểm định theo mã kiểm tra (RAM, ROM...)
  EvalResult evaluate(String testKey, Map<String, dynamic> payload) {
    switch (testKey.toLowerCase()) {
      case 'ram':
        return _evalRam(payload);
      case 'rom':
        return _evalRom(payload);
      default:
        return EvalResult.skip;
    }
  }

  /// Public wrapper đánh giá RAM
  EvalResult evalRam(Map<String, dynamic> payload) => _evalRam(payload);

  /// Public wrapper đánh giá ROM
  EvalResult evalRom(Map<String, dynamic> payload) => _evalRom(payload);

  /// Đánh giá RAM
  /// - iOS: Có thể là estimated value -> vẫn PASS
  /// - Android: Yêu cầu totalBytes > 0
  EvalResult _evalRam(Map<String, dynamic> p) {
    final source = p['source'] as String?;
    final total = p['totalBytes'];
    final totalGB = p['totalGB'];

    // iOS estimated: vẫn PASS vì hệ thống đã ước tính chuẩn theo model
    if (source == 'ios_estimated' && totalGB != null) {
      return EvalResult.pass;
    }

    // Nếu không đọc được dung lượng RAM
    if (total == null || total == 0) {
      // Nếu là iOS và không đọc được -> SKIP do chính sách bảo mật Sandbox của Apple
      if (source?.startsWith('ios') == true) {
        return EvalResult.skip;
      }
      // Trên Android nếu không đọc được RAM -> FAIL
      return EvalResult.fail;
    }

    return EvalResult.pass;
  }

  /// Đánh giá ROM/Storage
  /// - iOS: Không cho phép đọc trực tiếp từ sandbox -> SKIP
  /// - Android: Yêu cầu totalBytes > 0
  EvalResult _evalRom(Map<String, dynamic> p) {
    final source = p['source'] as String?;
    final total = p['totalBytes'];

    // iOS: Không cho phép đọc dung lượng bộ nhớ chính xác -> SKIP
    if (source == 'ios_unavailable') {
      return EvalResult.skip;
    }

    if (total == null || total == 0) {
      if (source?.startsWith('ios') == true) {
        return EvalResult.skip;
      }
      return EvalResult.fail;
    }

    return EvalResult.pass;
  }
}
