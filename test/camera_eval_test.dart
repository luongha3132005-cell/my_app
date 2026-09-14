import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';
import 'package:my_app/app/modules/camera_test/camera_test_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuleEvaluator - evalCamera Unit Tests', () {
    const evaluator = RuleEvaluator();

    test('Returns pass when both backCamera and frontCamera are true', () {
      final payload = {
        'permission': true,
        'backCamera': true,
        'frontCamera': true,
        'flash': true,
        'userConfirm': true,
      };

      final result = evaluator.evalCamera(payload);
      expect(result, EvalResult.pass);
      expect(result.isPass, isTrue);

      final evalGeneric = evaluator.evaluate('camera', payload);
      expect(evalGeneric, EvalResult.pass);
    });

    test('Returns skip when camera permission is denied', () {
      final payload = {
        'permission': false,
        'backCamera': false,
        'frontCamera': false,
        'userConfirm': false,
      };

      final result = evaluator.evalCamera(payload);
      expect(result, EvalResult.skip);
      expect(result.isSkip, isTrue);
    });

    test('Returns skip when device has no camera hardware', () {
      final payload = {
        'permission': true,
        'noCameras': true,
        'backCamera': false,
        'frontCamera': false,
      };

      final result = evaluator.evalCamera(payload);
      expect(result, EvalResult.skip);
    });

    test('Returns fail when only back camera passes but front camera fails', () {
      final payload = {
        'permission': true,
        'backCamera': true,
        'frontCamera': false,
        'userConfirm': false,
      };

      final result = evaluator.evalCamera(payload);
      expect(result, EvalResult.fail);
      expect(result.isFail, isTrue);
    });

    test('Returns fail when back camera fails but front camera passes', () {
      final payload = {
        'permission': true,
        'backCamera': false,
        'frontCamera': true,
        'userConfirm': false,
      };

      final result = evaluator.evalCamera(payload);
      expect(result, EvalResult.fail);
    });

    test('Returns skip when payload is empty', () {
      final result = evaluator.evalCamera({});
      expect(result, EvalResult.skip);
    });
  });

  group('CameraTestController Unit Tests', () {
    test('Initializes with default step backPreview', () {
      final controller = CameraTestController();

      expect(controller.currentStep.value, CameraTestStep.backPreview);
      expect(controller.isCameraInitialized.value, isFalse);
      expect(controller.isTakingPhoto.value, isFalse);
      expect(controller.isFlashOn.value, isFalse);
      expect(controller.backCameraPassed.value, isFalse);
      expect(controller.frontCameraPassed.value, isFalse);
      expect(controller.isCompleted, isFalse);

      controller.onClose();
    });

    test('confirmComparison updates state and finishes test when completed', () async {
      final controller = CameraTestController();

      // Giả lập đang ở bước so khớp Cam sau
      controller.currentStep.value = CameraTestStep.backCompare;
      await controller.confirmComparison(true);
      expect(controller.backCameraPassed.value, isTrue);

      // Giả lập ở bước so khớp Cam trước
      controller.currentStep.value = CameraTestStep.frontCompare;
      await controller.confirmComparison(true);
      expect(controller.frontCameraPassed.value, isTrue);
      expect(controller.currentStep.value, CameraTestStep.completed);
      expect(controller.isCompleted, isTrue);
      expect(controller.areBothCamerasPassed, isTrue);

      controller.onClose();
    });

    test('retakePhoto navigates back to preview step', () {
      final controller = CameraTestController();

      controller.currentStep.value = CameraTestStep.backCompare;
      controller.retakePhoto();
      expect(controller.currentStep.value, CameraTestStep.backPreview);

      controller.currentStep.value = CameraTestStep.frontCompare;
      controller.retakePhoto();
      expect(controller.currentStep.value, CameraTestStep.frontPreview);

      controller.onClose();
    });
  });
}
