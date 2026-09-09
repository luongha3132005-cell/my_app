import 'package:get/get.dart';
import '../core/loading/loading_service.dart';
import '../data/provider/api_provider.dart';

/// Global application-level bindings initialized before app run
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Core services
    Get.put<LoadingService>(LoadingService(), permanent: true);

    // Global networking provider
    Get.put<ApiProvider>(ApiProvider(), permanent: true);
  }
}
