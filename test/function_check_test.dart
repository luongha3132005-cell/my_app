import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';
import 'package:my_app/app/modules/funtion_check/funtion_check_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FuntionCheckController Unit Tests', () {
    test('Controller initializes with default state', () {
      final controller = FuntionCheckController(
        ruleEvaluator: const RuleEvaluator(),
      );

      expect(controller.functionSteps.length, 6);
      expect(controller.functionSteps.map((s) => s.code).toList(), [
        'ram',
        'rom',
        'wifi',
        'bt',
        'gps',
        'vibrate',
      ]);
      expect(controller.hasStartedCheck.value, isFalse);
      expect(controller.isLoading.value, isFalse);
      expect(controller.ramEvalResult.value, isNull);
      expect(controller.romEvalResult.value, isNull);
      expect(controller.wifiEvalResult.value, isNull);
      expect(controller.btEvalResult.value, isNull);
      expect(controller.gpsEvalResult.value, isNull);
      expect(controller.vibrateEvalResult.value, isNull);
    });

    test('runFunctionCheck does not run when hasStartedCheck is false', () async {
      final controller = FuntionCheckController(
        ruleEvaluator: const RuleEvaluator(),
      );

      expect(controller.hasStartedCheck.value, isFalse);
      await controller.runFunctionCheck();

      // Vẫn giữ nguyên trạng thái chưa chạy
      expect(controller.isLoading.value, isFalse);
      expect(controller.hasStartedCheck.value, isFalse);
      expect(controller.currentStepTitle.value, isEmpty);
    });
  });
}
