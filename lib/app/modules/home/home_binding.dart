import 'package:get/get.dart';
import 'home_controller.dart';

/// Dependency injection binding for Home module
class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
