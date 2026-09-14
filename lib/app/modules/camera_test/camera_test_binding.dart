import 'package:get/get.dart';
import '../../data/provider/api_provider.dart';
import 'camera_test_controller.dart';
import 'camera_test_repository.dart';

/// Binding đăng ký phụ thuộc cho CameraTest module theo chuẩn GetX
class CameraTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CameraTestRepository>(
      () => CameraTestRepository(
        apiProvider: Get.isRegistered<ApiProvider>()
            ? Get.find<ApiProvider>()
            : ApiProvider(),
      ),
    );

    Get.lazyPut<CameraTestController>(
      () => CameraTestController(
        repository: Get.find<CameraTestRepository>(),
      ),
    );
  }
}
