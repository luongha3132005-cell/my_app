import 'package:get/get.dart';
import 'package:my_app/app/modules/funtion_check/funtion_check_controller.dart';

class FuntionCheckBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FuntionCheckController>(() => FuntionCheckController());
  }
}
