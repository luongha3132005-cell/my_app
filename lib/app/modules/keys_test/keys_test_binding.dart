import 'package:get/get.dart';
import '../../data/provider/api_provider.dart';
import 'keys_test_controller.dart';
import 'keys_test_repository.dart';

/// Binding đăng ký phụ thuộc cho KeysTest module theo chuẩn GetX
class KeysTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<KeysTestRepository>(
      () => KeysTestRepository(
        apiProvider: Get.isRegistered<ApiProvider>()
            ? Get.find<ApiProvider>()
            : ApiProvider(),
      ),
    );

    Get.lazyPut<KeysTestController>(
      () => KeysTestController(
        repository: Get.find<KeysTestRepository>(),
      ),
    );
  }
}
