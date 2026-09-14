import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/model/device_profile.dart';
import 'package:my_app/app/data/services/device_name_mapper.dart';
import 'package:my_app/app/data/services/diagnostics/device_os_diagnostic.dart';
import 'package:my_app/app/data/services/rule_evaluator.dart';
import 'package:my_app/app/modules/diagnostics_home/widgets/device_info_section.dart';

void main() {
  group('DeviceNameMapper Tests', () {
    test('Maps Samsung model codes to marketing names', () {
      expect(
        DeviceNameMapper.getMarketingName('SM-G991N', 'Samsung'),
        'Galaxy S21 5G',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-S901B', 'Samsung'),
        'Galaxy S22',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-S928B', 'Samsung'),
        'Galaxy S24 Ultra',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-F946B', 'Samsung'),
        'Galaxy Z Fold5',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-A546E', 'Samsung'),
        'Galaxy A54 5G',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-N975F', 'Samsung'),
        'Galaxy Note10+',
      );
    });

    test('Maps Xiaomi and Redmi model codes to marketing names', () {
      expect(
        DeviceNameMapper.getMarketingName('2201123G', 'Xiaomi'),
        'Xiaomi 12',
      );
      expect(
        DeviceNameMapper.getMarketingName('23116PN5BC', 'Xiaomi'),
        'Xiaomi 14 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('21091116AG', 'Xiaomi'),
        'Redmi Note 11',
      );
    });

    test('Maps Oppo and Vivo models to marketing names', () {
      expect(
        DeviceNameMapper.getMarketingName('CPH2531', 'Oppo'),
        'Oppo Reno10 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('V2227', 'Vivo'),
        'Vivo X90 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('V2143', 'Vivo'),
        'Vivo T1x',
      );
    });

    test('Maps Google Pixel and iPhone models', () {
      expect(
        DeviceNameMapper.getMarketingName('Pixel 8 Pro', 'Google'),
        'Pixel 8 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('iPhone14,2', 'Apple'),
        'iPhone 13 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('iPhone16,2', 'Apple'),
        'iPhone 15 Pro Max',
      );
    });

    test('Smart Hardware Detection: Maps accurately even if brand name is modified or fake', () {
      expect(
        DeviceNameMapper.getMarketingName('SM-S928B', 'FakeBrand'),
        'Galaxy S24 Ultra',
      );
      expect(
        DeviceNameMapper.getMarketingName('SM-N975F', 'CustomPhone'),
        'Galaxy Note10+',
      );
      expect(
        DeviceNameMapper.getMarketingName('V2143', 'UnknownBrand'),
        'Vivo T1x',
      );
      expect(
        DeviceNameMapper.getMarketingName('CPH2531', 'ModifiedBrand'),
        'Oppo Reno10 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('23116PN5BC', 'RandomBrand'),
        'Xiaomi 14 Pro',
      );
      expect(
        DeviceNameMapper.getMarketingName('iPhone16,2', 'FakeBrand'),
        'iPhone 15 Pro Max',
      );
    });
  });

  group('RuleEvaluator Tests', () {
    const evaluator = RuleEvaluator();

    test('Evaluates valid Android RAM as pass', () {
      final payload = {
        'totalBytes': 8589934592, // 8GB
        'freeBytes': 4294967296, // 4GB
        'source': 'android_native',
      };
      final result = evaluator.evalRam(payload);
      expect(result, EvalResult.pass);
    });

    test('Evaluates iOS estimated RAM with totalGB as pass', () {
      final payload = {
        'totalBytes': 6442450944,
        'totalGB': 6,
        'source': 'ios_estimated',
      };
      final result = evaluator.evalRam(payload);
      expect(result, EvalResult.pass);
    });

    test('Evaluates null totalBytes on Android as fail', () {
      final payload = {
        'totalBytes': null,
        'freeBytes': null,
        'source': 'android_error',
      };
      final result = evaluator.evalRam(payload);
      expect(result, EvalResult.fail);
    });

    test('Evaluates null totalBytes on iOS as skip', () {
      final payload = {
        'totalBytes': null,
        'freeBytes': null,
        'source': 'ios_unavailable',
      };
      final result = evaluator.evalRam(payload);
      expect(result, EvalResult.skip);
    });

    test('Evaluates ROM storage correctly', () {
      final androidRom = {
        'totalBytes': 137438953472, // 128GB
        'freeBytes': 68719476736,
        'source': 'android_native',
      };
      expect(evaluator.evalRom(androidRom), EvalResult.pass);

      final iosRom = {
        'totalBytes': null,
        'source': 'ios_unavailable',
      };
      expect(evaluator.evalRom(iosRom), EvalResult.skip);
    });

    test('Evaluates biometrics correctly with profile requirements', () {
      // 1. canCheck is false -> Skip (no screen lock or PIN set)
      expect(
        evaluator.evalBiometrics({'canCheck': false, 'supported': true}),
        EvalResult.skip,
      );

      // 2. canCheck is true, supported is true -> Pass
      expect(
        evaluator.evalBiometrics({'canCheck': true, 'supported': true}),
        EvalResult.pass,
      );

      // 3. canCheck is true, supported is false, profile requires bio -> Fail
      expect(
        evaluator.evalBiometrics(
          {'canCheck': true, 'supported': false},
          profile: const DeviceProfile(name: 'iPhone 13', bio: true),
        ),
        EvalResult.fail,
      );

      // 4. canCheck is true, supported is false, profile does NOT require bio -> Skip
      expect(
        evaluator.evalBiometrics(
          {'canCheck': true, 'supported': false},
          profile: const DeviceProfile(name: 'Legacy Phone', bio: false),
        ),
        EvalResult.skip,
      );
    });

    test('Evaluates microphone correctly based on permission and user confirmation', () {
      // 1. Permission denied -> Warning
      expect(
        evaluator.evalMicrophone({'permission': false, 'userConfirm': false}),
        EvalResult.warning,
      );

      // 2. Permission granted, user confirms hearing playback -> Pass
      expect(
        evaluator.evalMicrophone({'permission': true, 'userConfirm': true}),
        EvalResult.pass,
      );

      // 3. Permission granted, user confirms NOT hearing -> Fail
      expect(
        evaluator.evalMicrophone({'permission': true, 'userConfirm': false}),
        EvalResult.fail,
      );
    });
  });

  group('DeviceProfile Model Tests', () {
    test('DeviceProfile serialization and default values', () {
      const defaultProfile = DeviceProfile(name: 'Pixel 7');
      expect(defaultProfile.bio, isFalse);

      final json = defaultProfile.toJson();
      expect(json['name'], 'Pixel 7');
      expect(json['bio'], isFalse);

      final fromJson = DeviceProfile.fromJson(const {
        'name': 'Galaxy S23',
        'bio': true,
      });
      expect(fromJson.name, 'Galaxy S23');
      expect(fromJson.bio, isTrue);

      final copied = fromJson.copyWith(bio: false);
      expect(copied.name, 'Galaxy S23');
      expect(copied.bio, isFalse);
    });
  });

  group('DeviceInfoSection Widget Test', () {
    testWidgets('Renders DeviceInfoSection with accurate specs and layout', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: DeviceInfoSection(
                modelName: 'SM-G991N',
                brand: 'Samsung',
                manufacturer: 'Samsung',
                platform: 'android',
                marketingName: 'Galaxy S21 5G',
                origin: 'Hàn Quốc',
                ramInfo: {
                  'totalBytes': 8589934592,
                  'freeBytes': 4294967296,
                },
                romInfo: {
                  'totalBytes': 137438953472,
                  'freeBytes': 68719476736,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check display name and brand
      expect(find.text('Galaxy S21 5G'), findsOneWidget);
      expect(find.text('SAMSUNG'), findsOneWidget);
      expect(find.text('Đủ điều kiện thu cũ'), findsOneWidget);
      expect(find.text('8 GB'), findsOneWidget);
      expect(find.text('128 GB'), findsOneWidget);
      expect(find.text('Hàn Quốc'), findsOneWidget);
    });

    testWidgets('Renders DeviceInfoSection with bioInfo capability chip', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: DeviceInfoSection(
                modelName: 'Pixel 8',
                brand: 'Google',
                manufacturer: 'Google',
                platform: 'android',
                bioInfo: {
                  'supported': true,
                  'canCheck': true,
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.fingerprint_rounded), findsOneWidget);
    });
  });

  group('DeviceOsDiagnostic IT_Code Tests', () {
    test('Builds IT_Code from model, RAM bytes and ROM bytes correctly', () {
      final itCode = DeviceOsDiagnostic.buildItCode(
        model: 'SM-S928B',
        ramInfo: {'totalBytes': 12 * 1024 * 1024 * 1024}, // 12GB
        romInfo: {'totalBytes': 512 * 1024 * 1024 * 1024}, // 512GB
      );
      expect(itCode, 'SM-S928B_12GB_512GB');
    });

    test('Builds IT_Code for Note 10+ with 10.89GB kernel RAM mapping to 12GB and 256GB ROM', () {
      final itCode = DeviceOsDiagnostic.buildItCode(
        model: 'SM-N975F',
        ramInfo: {'totalBytes': (10.89 * 1024 * 1024 * 1024).round()}, // Kernel reports ~10.89GB
        romInfo: {'totalBytes': (228.5 * 1024 * 1024 * 1024).round()}, // StatFs reports ~228.5GB
      );
      expect(itCode, 'SM-N975F_12GB_256GB');
    });

    test('Builds IT_Code for Vivo V2143 with 47.6GB data partition mapping to 64GB ROM', () {
      final itCode = DeviceOsDiagnostic.buildItCode(
        model: 'V2143',
        ramInfo: {'totalBytes': (3.65 * 1024 * 1024 * 1024).round()}, // ~3.65GB RAM
        romInfo: {'totalBytes': (47.6 * 1024 * 1024 * 1024).round()}, // ~47.6GB StatFs ROM
      );
      expect(itCode, 'V2143_4GB_64GB');
    });

    test('Builds IT_Code for iOS with totalGB RAM', () {
      final itCode = DeviceOsDiagnostic.buildItCode(
        model: 'iPhone16,2',
        ramInfo: {'totalGB': 8},
        romInfo: null,
      );
      expect(itCode, 'iPhone16,2_8GB_0GB');
    });

    test('Builds IT_Code with empty or null info fallback', () {
      final itCode = DeviceOsDiagnostic.buildItCode(
        model: 'Pixel 8 Pro',
        ramInfo: null,
        romInfo: null,
      );
      expect(itCode, 'Pixel_8_Pro_0GB_0GB');
    });
  });
}
