/// ProfileManager - Quản lý hồ sơ và đặc thù phần cứng/hệ điều hành theo hãng sản xuất (OEM)
class ProfileManager {
  ProfileManager._();

  /// Danh sách các hãng máy tùy biến Android (như MIUI/HyperOS, ColorOS, OriginOS)
  /// có cơ chế kiểm soát định vị nghiêm ngặt khi quét Wi-Fi hoặc Bluetooth
  static const List<String> _locationStrictBrands = [
    'xiaomi',
    'redmi',
    'poco',
    'oppo',
    'realme',
    'oneplus',
    'vivo',
    'iqoo',
    'huawei',
    'honor',
  ];

  /// Kiểm tra xem hãng máy có bắt buộc bật định vị (GPS) để đọc thông tin Wi-Fi (SSID) hay không.
  /// Trên hầu hết các thiết bị Android 8+ và đặc biệt là MIUI/ColorOS, nếu GPS tắt thì getWifiName() trả về `<unknown ssid>`.
  static bool requiresLocationForWifi(String? brand) {
    if (brand == null || brand.isEmpty) return true;
    final b = brand.toLowerCase();
    return _locationStrictBrands.any((strictBrand) => b.contains(strictBrand)) || true;
  }

  /// Kiểm tra xem hãng máy có đặc thù bắt buộc bật định vị (GPS) để quét Bluetooth LE hay không.
  /// Các dòng máy Xiaomi (MIUI / HyperOS) và Oppo yêu cầu cả quyền Bluetooth và bật GPS vị trí để quét được thiết bị xung quanh.
  static bool requiresLocationForBluetooth(String? brand) {
    if (brand == null || brand.isEmpty) return false;
    final b = brand.toLowerCase();
    return _locationStrictBrands.any((strictBrand) => b.contains(strictBrand));
  }

  /// Kiểm tra xem thiết bị có phải là dòng máy Xiaomi / MIUI hay không
  static bool isMiuiOrXiaomi(String? brand) {
    if (brand == null) return false;
    final b = brand.toLowerCase();
    return b.contains('xiaomi') || b.contains('redmi') || b.contains('poco');
  }
}
