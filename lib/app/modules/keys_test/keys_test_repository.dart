import '../../data/provider/api_provider.dart';

/// Repository cho module KeysTest, thực thi các truy vấn dữ liệu IO/API liên quan đến phím vật lý
class KeysTestRepository {
  final ApiProvider apiProvider;

  KeysTestRepository({required this.apiProvider});

  /// Gửi kết quả kiểm định phím vật lý lên hệ thống nếu có kết nối API
  Future<bool> submitKeysTestResult(Map<String, dynamic> payload) async {
    try {
      return await apiProvider.safeCall<bool>(
        () async {
          // Endpoint đồng bộ API khi có backend:
          // await apiProvider.dio.post('/api/diagnostics/keys', data: payload);
          return true;
        },
        showLoading: false,
        handleErrors: false,
      );
    } catch (_) {
      return false;
    }
  }
}
