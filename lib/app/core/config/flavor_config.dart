import 'package:flutter_dotenv/flutter_dotenv.dart';

enum Flavor { dev, stg, prod }

class FlavorConfig {
  final Flavor flavor;
  final String appName;
  final String baseUrl;
  final bool enableLogging;

  static FlavorConfig? _instance;

  FlavorConfig._({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
    required this.enableLogging,
  });

  static FlavorConfig get instance {
    if (_instance == null) {
      throw StateError(
        'FlavorConfig has not been initialized. Call FlavorConfig.init() first.',
      );
    }
    return _instance!;
  }

  static bool get isInitialized => _instance != null;

  static bool get isDev => instance.flavor == Flavor.dev;
  static bool get isStg => instance.flavor == Flavor.stg;
  static bool get isProd => instance.flavor == Flavor.prod;

  static Future<FlavorConfig> init({String? envArg}) async {
    final rawEnv = (envArg ?? const String.fromEnvironment('ENV', defaultValue: 'dev')).toLowerCase();

    final Flavor flavor;
    final String envFile;
    final String flavorSuffix;

    switch (rawEnv) {
      case 'prod':
      case 'production':
        flavor = Flavor.prod;
        envFile = 'assets/env/.env.prod';
        flavorSuffix = '';
        break;
      case 'stg':
      case 'staging':
        flavor = Flavor.stg;
        envFile = 'assets/env/.env.stg';
        flavorSuffix = ' [STG]';
        break;
      case 'dev':
      case 'development':
      default:
        flavor = Flavor.dev;
        envFile = 'assets/env/.env.dev';
        flavorSuffix = ' [DEV]';
        break;
    }

    await dotenv.load(fileName: envFile);

    final baseUrl = dotenv.get('BASE_URL', fallback: 'https://dummyjson.com');
    final enableLogging = dotenv.get('ENABLE_LOGGING', fallback: 'true').toLowerCase() == 'true';
    final appName = 'My App$flavorSuffix';

    _instance = FlavorConfig._(
      flavor: flavor,
      appName: appName,
      baseUrl: baseUrl,
      enableLogging: enableLogging,
    );

    return _instance!;
  }
}
