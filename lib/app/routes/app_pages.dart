import 'package:get/get.dart';
import '../modules/diagnostics_home/diagnostics_home_binding.dart';
import '../modules/diagnostics_home/diagnostics_home_page.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_page.dart';
import 'app_routes.dart';

/// Centralized GetPage registrations and initial routing
class AppPages {
  AppPages._();

  static const initial = AppRoutes.home;

  static final routes = <GetPage>[
    // Home module
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      binding: HomeBinding(),
      transition: Transition.fadeIn,
    ),
    // Diagnostics Home module
    GetPage(
      name: AppRoutes.diagnosticsHome,
      page: () => const DiagnosticsHomePage(),
      binding: DiagnosticsHomeBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
