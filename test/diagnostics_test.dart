import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/device_name_mapper.dart';
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
  });
}
