import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/app/core/config/flavor_config.dart';
import 'package:my_app/app/core/errors/app_exception.dart';
import 'package:my_app/app/core/errors/error_handler.dart';
import 'package:my_app/app/core/loading/loading_service.dart';
import 'package:my_app/app/data/model/product_model.dart';
import 'package:my_app/app/data/model/todo_model.dart';
import 'package:my_app/app/data/model/user_model.dart';
import 'package:my_app/app/my_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FlavorConfig.init(envArg: 'dev');
  });

  group('Data Models Tests', () {
    test('UserModel fromJson and toJson serialization', () {
      final json = {
        'id': 1,
        'username': 'emilys',
        'email': 'emily.johnson@x.dummyjson.com',
        'firstName': 'Emily',
        'lastName': 'Johnson',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, 1);
      expect(user.username, 'emilys');
      expect(user.fullName, 'Emily Johnson');

      final serialized = user.toJson();
      expect(serialized['username'], 'emilys');
    });

    test('TodoModel copyWith and JSON roundtrip', () {
      final original = const TodoModel(
        id: 10,
        todo: 'Test task',
        completed: false,
        userId: 1,
      );

      final updated = original.copyWith(completed: true);
      expect(updated.completed, true);
      expect(updated.id, original.id);

      final json = original.toJson();
      final parsed = TodoModel.fromJson(json);
      expect(parsed, original);
    });

    test('ProductModel calculates discounted price correctly', () {
      final product = const ProductModel(
        id: 1,
        title: 'Smartphone',
        price: 100.0,
        discountPercentage: 20.0,
      );

      expect(product.discountedPrice, 80.0);
    });
  });

  group('Core Services Tests', () {
    test('ErrorHandler normalizes exceptions properly', () {
      final customEx = const NetworkException(message: 'Connection failed');
      final normalized = ErrorHandler.normalize(customEx);
      expect(normalized, isA<NetworkException>());
      expect(normalized.message, 'Connection failed');

      final stdEx = Exception('Generic error');
      final normalizedStd = ErrorHandler.normalize(stdEx);
      expect(normalizedStd, isA<UnknownException>());
      expect(normalizedStd.message, 'Generic error');
    });

    test('LoadingService toggles reactive state', () {
      final service = LoadingService();
      expect(service.isLoading, false);
      expect(service.message, null);

      service.show(message: 'Processing...');
      expect(service.isLoading, true);
      expect(service.message, 'Processing...');

      service.hide();
      expect(service.isLoading, false);
      expect(service.message, null);
    });
  });

  group('Widget Tests', () {
    testWidgets('MyApp builds successfully and renders home screen', (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(milliseconds: 200));

      // Verify app UI elements are rendered
      expect(find.byType(MyApp), findsOneWidget);
    });
  });
}
