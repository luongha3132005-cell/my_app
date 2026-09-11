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
      case 'wifi':
        return _evalWifi(payload);
      case 'bt':
      case 'bluetooth':
        return _evalBluetooth(payload);
      default:
        return EvalResult.skip;
    }
  }

  /// Public wrapper đánh giá RAM
  EvalResult evalRam(Map<String, dynamic> payload) => _evalRam(payload);

  /// Public wrapper đánh giá ROM
  EvalResult evalRom(Map<String, dynamic> payload) => _evalRom(payload);

  /// Public wrapper đánh giá Wi-Fi
  EvalResult evalWifi(Map<String, dynamic> payload) => _evalWifi(payload);

  /// Public wrapper đánh giá Bluetooth
  EvalResult evalBluetooth(Map<String, dynamic> payload) => _evalBluetooth(payload);

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

  /// Đánh giá Wi-Fi (dòng 374-391)
  /// - enabled: Wi-Fi đang bật hay tắt. Nếu tắt -> SKIP (không phải lỗi phần cứng)
  /// - connected: Đang kết nối tới một mạng Wi-Fi
  /// - ssid: Tên mạng Wi-Fi
  EvalResult _evalWifi(Map<String, dynamic> p) {
    final enabled = p['enabled'] as bool? ?? false;
    final connected = p['connected'] as bool? ?? false;
    final ssid = p['ssid'] as String?;

    // Nếu Wi-Fi đang tắt thì tính là SKIP (không phải lỗi phần cứng)
    if (!enabled) {
      return EvalResult.skip;
    }

    // Nếu Wi-Fi bật và đã kết nối thành công
    if (connected) {
      return EvalResult.pass;
    }

    // Nếu đọc được SSID hợp lệ
    if (ssid != null && ssid.isNotEmpty && ssid != '<unknown ssid>') {
      return EvalResult.pass;
    }

    // Wi-Fi đã bật nhưng chưa kết nối mạng
    return EvalResult.warning;
  }

  /// Đánh giá Bluetooth (dòng 393-404)
  /// - enabled: Adapter Bluetooth đang bật hay tắt
  /// - hasScanPermission: Đã được cấp quyền quét Bluetooth
  /// - scanOk: Quá trình quét tìm thiết bị xung quanh thành công
  /// - isMiui: Thiết bị có đặc thù MIUI (cần bật GPS mới scan được)
  /// - isGpsOn: Trạng thái GPS
  EvalResult _evalBluetooth(Map<String, dynamic> p) {
    final enabled = p['enabled'] as bool? ?? false;
    final hasScanPermission = p['hasScanPermission'] as bool? ?? true;
    final scanOk = p['scanOk'] as bool? ?? false;
    final isMiui = p['isMiui'] as bool? ?? false;
    final isGpsOn = p['isGpsOn'] as bool? ?? true;

    // Nếu Bluetooth đang tắt -> SKIP (không phải lỗi phần cứng)
    if (!enabled) {
      return EvalResult.skip;
    }

    // Kiểm tra quyền bluetoothScan
    if (!hasScanPermission) {
      return EvalResult.warning;
    }

    // Kiểm tra đặc thù MIUI (cần bật GPS mới scan được Bluetooth)
    if (isMiui && !isGpsOn && !scanOk) {
      return EvalResult.warning;
    }

    // Kiểm tra scanOk để trả về pass hoặc fail
    if (scanOk) {
      return EvalResult.pass;
    }

    return EvalResult.fail;
  }
}
