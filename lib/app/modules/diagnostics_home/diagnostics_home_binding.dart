import 'package:get/get.dart';
import '../../data/provider/api_provider.dart';
import 'diagnostics_home_controller.dart';
import 'diagnostics_home_repository.dart';

/// Binding đăng ký phụ thuộc cho DiagnosticsHome module
class DiagnosticsHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosticsHomeRepository>(
      () => DiagnosticsHomeRepository(apiProvider: Get.find<ApiProvider>()),
    );
    Get.lazyPut<DiagnosticsHomeController>(
      () => DiagnosticsHomeController(
        repository: Get.find<DiagnosticsHomeRepository>(),
      ),
    );
  }
}
