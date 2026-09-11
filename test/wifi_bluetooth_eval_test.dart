import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/profile_manager.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';

void main() {
  const evaluator = RuleEvaluator();

  group('RuleEvaluator - Wi-Fi Evaluation Tests', () {
    test('Wi-Fi disabled should return SKIP (not hardware failure)', () {
      final result = evaluator.evalWifi({
        'enabled': false,
        'connected': false,
        'ssid': null,
      });
      expect(result, EvalResult.skip);
    });

    test('Wi-Fi enabled and connected should return PASS', () {
      final result = evaluator.evalWifi({
        'enabled': true,
        'connected': true,
        'ssid': 'MyHome_5G',
      });
      expect(result, EvalResult.pass);
    });

    test('Wi-Fi enabled and connected even without SSID should return PASS', () {
      final result = evaluator.evalWifi({
        'enabled': true,
        'connected': true,
        'ssid': null,
      });
      expect(result, EvalResult.pass);
    });

    test('Wi-Fi enabled but not connected should return WARNING', () {
      final result = evaluator.evalWifi({
        'enabled': true,
        'connected': false,
        'ssid': null,
      });
      expect(result, EvalResult.warning);
    });
  });

  group('RuleEvaluator - Bluetooth Evaluation Tests', () {
    test('Bluetooth disabled should return SKIP', () {
      final result = evaluator.evalBluetooth({
        'enabled': false,
        'scanOk': false,
        'hasScanPermission': true,
      });
      expect(result, EvalResult.skip);
    });

    test('Bluetooth enabled, permission granted and scanOk should return PASS', () {
      final result = evaluator.evalBluetooth({
        'enabled': true,
        'scanOk': true,
        'hasScanPermission': true,
      });
      expect(result, EvalResult.pass);
    });

    test('Bluetooth enabled but missing permission should return WARNING', () {
      final result = evaluator.evalBluetooth({
        'enabled': true,
        'scanOk': false,
        'hasScanPermission': false,
      });
      expect(result, EvalResult.warning);
    });

    test('Bluetooth enabled with permission but scan failed should return FAIL', () {
      final result = evaluator.evalBluetooth({
        'enabled': true,
        'scanOk': false,
        'hasScanPermission': true,
        'isMiui': false,
      });
      expect(result, EvalResult.fail);
    });

    test('MIUI device with GPS off and scan failed should return WARNING', () {
      final result = evaluator.evalBluetooth({
        'enabled': true,
        'scanOk': false,
        'hasScanPermission': true,
        'isMiui': true,
        'isGpsOn': false,
      });
      expect(result, EvalResult.warning);
    });
  });

  group('ProfileManager Tests', () {
    test('Identifies OEM brands requiring location for Bluetooth', () {
      expect(ProfileManager.requiresLocationForBluetooth('Xiaomi'), isTrue);
      expect(ProfileManager.requiresLocationForBluetooth('Redmi'), isTrue);
      expect(ProfileManager.requiresLocationForBluetooth('POCO'), isTrue);
      expect(ProfileManager.requiresLocationForBluetooth('Oppo'), isTrue);
      expect(ProfileManager.requiresLocationForBluetooth('Vivo'), isTrue);
      expect(ProfileManager.requiresLocationForBluetooth('Samsung'), isFalse);
      expect(ProfileManager.requiresLocationForBluetooth('Apple'), isFalse);
    });

    test('Identifies MIUI/Xiaomi devices', () {
      expect(ProfileManager.isMiuiOrXiaomi('Xiaomi'), isTrue);
      expect(ProfileManager.isMiuiOrXiaomi('Redmi Note 12'), isTrue);
      expect(ProfileManager.isMiuiOrXiaomi('POCO X5'), isTrue);
      expect(ProfileManager.isMiuiOrXiaomi('Samsung'), isFalse);
    });
  });
}
