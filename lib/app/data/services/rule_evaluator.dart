import '../model/device_profile.dart';

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
  final DeviceProfile? defaultProfile;

  const RuleEvaluator({this.defaultProfile});

  /// Đánh giá kết quả kiểm định theo mã kiểm tra (RAM, ROM, Biometrics...)
  EvalResult evaluate(String testKey, Map<String, dynamic> payload, {DeviceProfile? profile}) {
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
      case 'gps':
        return _evalGps(payload);
      case 'vibrate':
      case 'vibration':
        return _evalVibration(payload);
      case 'bio':
      case 'biometric':
      case 'biometrics':
        return _evalBio(payload, profile: profile ?? defaultProfile);
      case 'mic':
      case 'microphone':
        return _evalMicrophone(payload);
      case 'keys':
      case 'key':
      case 'buttons':
      case 'volume':
        return _evalKeys(payload);
      case 'camera':
      case 'cam':
        return _evalCamera(payload);
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

  /// Public wrapper đánh giá GPS
  EvalResult evalGps(Map<String, dynamic> payload) => _evalGps(payload);

  /// Public wrapper đánh giá Rung
  EvalResult evalVibration(Map<String, dynamic> payload) => _evalVibration(payload);

  /// Public wrapper đánh giá Sinh trắc học (Biometrics)
  EvalResult evalBiometrics(Map<String, dynamic> payload, {DeviceProfile? profile}) =>
      _evalBio(payload, profile: profile ?? defaultProfile);

  /// Public wrapper đánh giá Microphone
  EvalResult evalMicrophone(Map<String, dynamic> payload) => _evalMicrophone(payload);

  /// Public wrapper đánh giá Phím vật lý (Tăng/Giảm âm lượng)
  EvalResult evalKeys(Map<String, dynamic> payload) => _evalKeys(payload);

  /// Public wrapper đánh giá Camera (Trước & Sau)
  EvalResult evalCamera(Map<String, dynamic> payload) => _evalCamera(payload);

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

  /// Đánh giá GPS (dòng 441-454)
  /// - serviceOn: Dịch vụ định vị GPS có đang bật hay không
  /// - accuracyM: Sai số vị trí tính bằng mét
  EvalResult _evalGps(Map<String, dynamic> p) {
    final serviceOn = p['serviceOn'] as bool? ?? false;
    final accuracyM = (p['accuracyM'] as num?)?.toDouble();

    // Nếu GPS bị tắt hoặc thiếu quyền vị trí thì trả về skip
    if (!serviceOn || accuracyM == null) {
      return EvalResult.skip;
    }

    // Nếu đo được độ lệch vị trí (sai số mét) <= 50m thì trả về pass, ngược lại fail
    if (accuracyM <= 50) {
      return EvalResult.pass;
    }

    return EvalResult.fail;
  }

  /// Đánh giá chức năng Rung (dòng 485-488)
  /// - supported: Thiết bị có hỗ trợ mô-tơ rung hay không
  /// - userConfirm: Người dùng chọn đúng số lần máy đã rung
  EvalResult _evalVibration(Map<String, dynamic> p) {
    final supported = p['supported'] as bool? ?? false;
    final userConfirm = p['userConfirm'] as bool? ?? false;

    // Nếu không hỗ trợ rung
    if (!supported) {
      return EvalResult.skip;
    }

    // Trả về pass nếu người dùng chọn đúng số lần máy đã rung (userConfirm == true)
    if (userConfirm) {
      return EvalResult.pass;
    }

    return EvalResult.fail;
  }

  /// Đánh giá Sinh trắc học (Vân tay, Face ID...)
  /// - canCheck: Thiết bị có cảm biến VÀ người dùng đã cài đặt vân tay/mặt trong Cài đặt máy
  /// - supported: Phần cứng máy có hỗ trợ công nghệ sinh trắc học không
  /// - profile: Cấu hình đời máy (có bắt buộc tính năng sinh trắc học không)
  EvalResult _evalBio(Map<String, dynamic> p, {DeviceProfile? profile}) {
    // 1. Kiểm tra xem người dùng đã cài mã PIN / bảo mật trên máy chưa
    final canCheck = p['canCheck'] == true;
    if (!canCheck) return EvalResult.skip; // Nếu chưa thiết lập bảo mật màn hình -> Bỏ qua

    final required = profile?.bio ?? false; // Đời máy này có bắt buộc phải có sinh trắc học không
    final supported = p['supported'] == true; // Máy thực tế có hỗ trợ phần cứng không

    // 2. Nếu profile không bắt buộc VÀ máy không hỗ trợ -> Skip (vd: máy cỏ, máy cổ)
    if (!required && !supported) return EvalResult.skip;

    // 3. Nếu máy thuộc đời bắt buộc phải có sinh trắc học mà phần cứng lại không hỗ trợ (hỏng cảm biến) -> Fail
    if (required && !supported) return EvalResult.fail;

    // 4. Nếu phần cứng hỗ trợ bình thường -> Pass
    return supported ? EvalResult.pass : EvalResult.skip;
  }

  /// Đánh giá Microphone (thu âm, đo biên độ sóng âm và xác nhận từ người dùng)
  /// - permission: Đã được cấp quyền Microphone
  /// - userConfirm: Người dùng xác nhận có nghe rõ âm thanh phát lại
  EvalResult _evalMicrophone(Map<String, dynamic> p) {
    final permission = p['permission'] as bool? ?? false;
    final userConfirm = p['userConfirm'] as bool? ?? false;

    // Nếu không được cấp quyền microphone -> Warning / Skip
    if (!permission) {
      return EvalResult.warning;
    }

    // Nếu người dùng xác nhận nghe rõ âm thanh vừa thu -> Pass
    if (userConfirm) {
      return EvalResult.pass;
    }

    // Nếu người dùng chọn "Không nghe thấy" -> Fail
    return EvalResult.fail;
  }

  /// Đánh giá phím vật lý (Tăng/Giảm âm lượng, Nguồn, Back)
  /// - volumeUp: Trạng thái phím Tăng âm lượng
  /// - volumeDown: Trạng thái phím Giảm âm lượng
  /// - Điều kiện ĐẠT: Bắt buộc cả 2 phím Vol+ và Vol- đều hoạt động
  EvalResult _evalKeys(Map<String, dynamic> p) {
    if (p.isEmpty) {
      return EvalResult.skip;
    }

    final volUp = p['volumeUp'] as bool? ?? false;
    final volDown = p['volumeDown'] as bool? ?? false;

    // Bắt buộc cả 2 phím âm lượng đều phải hoạt động
    if (volUp && volDown) {
      return EvalResult.pass;
    }

    return EvalResult.fail;
  }

  /// Đánh giá Camera trước & sau (so khớp hình chụp và độ phản hồi cảm biến)
  /// - permission: Đã được cấp quyền Camera hay chưa. Nếu chưa cấp -> SKIP (không phải lỗi phần cứng)
  /// - backCamera: Camera sau hoạt động tốt, hình chụp khớp với thực tế
  /// - frontCamera: Camera trước hoạt động tốt, hình chụp khớp với thực tế
  /// - noCameras: Thiết bị không có camera nào -> SKIP
  EvalResult _evalCamera(Map<String, dynamic> p) {
    if (p.isEmpty) {
      return EvalResult.skip;
    }

    final permission = p['permission'] as bool? ?? false;
    final noCameras = p['noCameras'] as bool? ?? false;

    // Nếu bị từ chối quyền Camera hoặc máy không có camera -> SKIP
    if (!permission || noCameras) {
      return EvalResult.skip;
    }

    final backCamera = p['backCamera'] as bool? ?? false;
    final frontCamera = p['frontCamera'] as bool? ?? false;

    // Cả 2 camera trước và sau đều phải hoạt động tốt và hình chụp khớp
    if (backCamera && frontCamera) {
      return EvalResult.pass;
    }

    // Nếu 1 trong 2 camera bị hỏng hoặc ảnh chụp không khớp -> FAIL
    return EvalResult.fail;
  }
}
