import 'package:get/get.dart';
import 'package:my_app/app/modules/funtion_check/funtion_check_binding.dart';
import 'package:my_app/app/modules/funtion_check/funtion_check_page.dart';
import '../modules/diagnostics_home/diagnostics_home_binding.dart';
import '../modules/diagnostics_home/diagnostics_home_page.dart';
import 'app_routes.dart';

/// Centralized GetPage registrations and initial routing
class AppPages {
  AppPages._();

  static const initial = AppRoutes.diagnosticsHome;

  static final routes = <GetPage>[
    // Diagnostics Home module
    GetPage(
      name: AppRoutes.diagnosticsHome,
      page: () => const DiagnosticsHomePage(),
      binding: DiagnosticsHomeBinding(),
      transition: Transition.rightToLeftWithFade,
    ),

    GetPage(
      name: AppRoutes.functionCheck,
      page: () => const FuntionCheckPage(),
      binding: FuntionCheckBinding(),
      transition: Transition.rightToLeftWithFade,
    ),
  ];
}
