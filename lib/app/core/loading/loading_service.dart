import 'package:get/get.dart';

class LoadingService extends GetxService {
  static LoadingService get to => Get.find<LoadingService>();

  final _isLoading = false.obs;
  final _message = RxnString();

  bool get isLoading => _isLoading.value;
  String? get message => _message.value;

  void show({String? message}) {
    _message.value = message;
    _isLoading.value = true;
  }

  void hide() {
    _isLoading.value = false;
    _message.value = null;
  }
}
