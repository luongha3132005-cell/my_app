import '../../data/provider/api_provider.dart';

/// Repository cho module CameraTest, thực thi các truy vấn IO/API liên quan đến thẩm định camera
class CameraTestRepository {
  final ApiProvider apiProvider;

  CameraTestRepository({required this.apiProvider});

  /// Gửi kết quả kiểm định camera lên hệ thống backend nếu có
  Future<bool> submitCameraTestResult(Map<String, dynamic> payload) async {
    try {
      return await apiProvider.safeCall<bool>(
        () async {
          // Endpoint đồng bộ khi có backend:
          // await apiProvider.dio.post('/api/diagnostics/camera', data: payload);
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
