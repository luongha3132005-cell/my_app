import 'package:flutter/material.dart';
import 'app/core/config/flavor_config.dart';
import 'app/my_app.dart';

/// Application entry point
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Read environment passed via --dart-define=ENV=... (default: dev)
  const env = String.fromEnvironment('ENV', defaultValue: 'dev');

  // Load environment config and .env file
  await FlavorConfig.init(envArg: env);

  // Run the application
  runApp(const MyApp());
}
