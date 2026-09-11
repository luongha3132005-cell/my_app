import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/data/services/diagnostics/diag_step.dart';
import 'package:my_app/app/data/services/diagnostics/ram_rom_diagnostic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Modular Diagnostics Tests', () {
    test('DiagStep model initializes correctly', () async {
      bool executed = false;
      final step = DiagStep(
        code: 'test_code',
        title: 'Test Step',
        run: () async {
          executed = true;
        },
      );

      expect(step.code, 'test_code');
      expect(step.title, 'Test Step');
      await step.run();
      expect(executed, isTrue);
    });

    test('RamRomDiagnostic reads RAM and ROM structure safely', () async {
      const diag = RamRomDiagnostic();
      final ram = await diag.checkRam();
      final rom = await diag.checkRom();

      expect(ram, isA<Map<String, dynamic>>());
      expect(rom, isA<Map<String, dynamic>>());
    });
  });
}
