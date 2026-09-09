import '../../data/provider/api_provider.dart';

/// Repository cho module DiagnosticsHome, thực thi các truy vấn dữ liệu IO/API
class DiagnosticsHomeRepository {
  final ApiProvider apiProvider;

  DiagnosticsHomeRepository({required this.apiProvider});

  /// Gửi kết quả chẩn đoán lên hệ thống (nếu có kết nối API)
  Future<bool> submitDiagnosticsResult(Map<String, dynamic> payload) async {
    try {
      return await apiProvider.safeCall<bool>(
        () async {
          // Khi có API endpoint thực tế:
          // await apiProvider.dio.post('/api/diagnostics', data: payload);
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
