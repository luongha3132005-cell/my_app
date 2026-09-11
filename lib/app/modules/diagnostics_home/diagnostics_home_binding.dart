import 'package:get/get.dart';
import 'diagnostics_home_controller.dart';

/// Binding đăng ký phụ thuộc cho DiagnosticsHome module
class DiagnosticsHomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiagnosticsHomeController>(() => DiagnosticsHomeController());
  }
}
