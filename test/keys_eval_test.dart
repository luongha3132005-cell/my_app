import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';
import 'package:my_app/app/modules/keys_test/keys_test_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RuleEvaluator - evalKeys Unit Tests', () {
    const evaluator = RuleEvaluator();

    test('Returns pass when both volumeUp and volumeDown are true', () {
      final payload = {
        'userConfirm': true,
        'volumeUp': true,
        'volumeDown': true,
        'back': false,
        'powerManualConfirm': false,
      };

      final result = evaluator.evalKeys(payload);
      expect(result, EvalResult.pass);
      expect(result.isPass, isTrue);

      // Evaluate via generic evaluate method
      final evalGeneric = evaluator.evaluate('keys', payload);
      expect(evalGeneric, EvalResult.pass);
    });

    test('Returns fail when only volumeUp is true', () {
      final payload = {
        'userConfirm': false,
        'volumeUp': true,
        'volumeDown': false,
      };

      final result = evaluator.evalKeys(payload);
      expect(result, EvalResult.fail);
      expect(result.isFail, isTrue);
    });

    test('Returns fail when only volumeDown is true', () {
      final payload = {
        'userConfirm': false,
        'volumeUp': false,
        'volumeDown': true,
      };

      final result = evaluator.evalKeys(payload);
      expect(result, EvalResult.fail);
    });

    test('Returns fail when neither volume key is pressed', () {
      final payload = {
        'userConfirm': false,
        'volumeUp': false,
        'volumeDown': false,
      };

      final result = evaluator.evalKeys(payload);
      expect(result, EvalResult.fail);
    });

    test('Returns skip when payload is empty', () {
      final result = evaluator.evalKeys({});
      expect(result, EvalResult.skip);
    });
  });

  group('KeysTestController Unit Tests', () {
    test('Initializes with default state correctly', () {
      final controller = KeysTestController();

      expect(controller.volUp.value, isFalse);
      expect(controller.volDown.value, isFalse);
      expect(controller.backPressed.value, isFalse);
      expect(controller.powerConfirmed.value, isFalse);
      expect(controller.isCompleted.value, isFalse);
      expect(controller.isFreeMode, isTrue);
      expect(controller.countdown.value, 5);

      controller.onClose();
    });

    test('Marking volume up and down updates state and completes test', () {
      final controller = KeysTestController();

      controller.markVolUp();
      expect(controller.volUp.value, isTrue);
      expect(controller.isCompleted.value, isFalse);

      controller.markVolDown();
      expect(controller.volDown.value, isTrue);
      expect(controller.areBothVolumeKeysWorking, isTrue);
      expect(controller.isCompleted.value, isTrue);

      controller.onClose();
    });

    test('Reset test clears key states and restarts countdown', () {
      final controller = KeysTestController();

      controller.markVolUp();
      controller.markVolDown();
      expect(controller.isCompleted.value, isTrue);

      controller.resetTest();
      expect(controller.volUp.value, isFalse);
      expect(controller.volDown.value, isFalse);
      expect(controller.isCompleted.value, isFalse);

      controller.onClose();
    });

    test('Sequential mode transitions from step 1 to step 2 to completed', () async {
      final controller = KeysTestController();

      controller.startSequentialMode();
      expect(controller.isSequentialMode, isTrue);
      expect(controller.sequentialStep.value, 1);

      controller.markVolUp();
      expect(controller.volUp.value, isTrue);

      // Chờ microtask delay 350ms chuyển bước sang step 2
      await Future.delayed(const Duration(milliseconds: 400));
      expect(controller.sequentialStep.value, 2);

      controller.markVolDown();
      expect(controller.volDown.value, isTrue);
      expect(controller.sequentialStep.value, 3);
      expect(controller.isCompleted.value, isTrue);

      controller.onClose();
    });
  });
}
