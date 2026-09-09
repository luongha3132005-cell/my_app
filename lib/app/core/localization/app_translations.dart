import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'en_us.dart';
import 'vi_vn.dart';

/// GetX translations registry
class AppTranslations extends Translations {
  // Supported locales
  static const fallbackLocale = Locale('en', 'US');
  static const enLocale = Locale('en', 'US');
  static const viLocale = Locale('vi', 'VN');

  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': enUS,
        'vi_VN': viVN,
      };
}
