import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'core/config/flavor_config.dart';
import 'core/loading/loading_overlay.dart';
import 'core/localization/app_translations.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_pages.dart';
import 'routes/initial_binding.dart';

/// Root application widget configuring ScreenUtilInit and GetMaterialApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Standard baseline canvas size (width: 375, height: 812)
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          // Dynamic app title with flavor suffix
          title: FlavorConfig.instance.appName,
          debugShowCheckedModeBanner: FlavorConfig.isDev,

          // Theming setup
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,

          // Localization setup
          translations: AppTranslations(),
          locale: AppTranslations.enLocale,
          fallbackLocale: AppTranslations.fallbackLocale,

          // Routing setup
          initialRoute: AppPages.initial,
          getPages: AppPages.routes,
          initialBinding: InitialBinding(),

          // Global reactive loading overlay wrapper
          builder: (context, widget) {
            return LoadingOverlay(child: widget ?? const SizedBox.shrink());
          },
        );
      },
    );
  }
}
