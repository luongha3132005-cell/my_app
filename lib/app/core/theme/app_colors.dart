import 'package:flutter/material.dart';

/// Centralized color palette management
class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);

  // Secondary & Accent
  static const Color secondary = Color(0xFF0D9488);
  static const Color secondaryLight = Color(0xFF2DD4BF);
  static const Color accent = Color(0xFFF59E0B);

  // Neutral backgrounds & surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1E293B);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Status & Feedback colors
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF0284C7);

  // Border & Divider colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // Common constants
  static const Color white = Colors.white;
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;

  // Trade-In & Diagnostics Palette
  static const Color tradeInNavy = Color(0xFF0F172A);
  static const Color tradeInDark = Color(0xFF1E293B);
  static const Color tradeInBlue = Color(0xFF2563EB);
  static const Color tradeInEmerald = Color(0xFF10B981);
  static const Color tradeInGold = Color(0xFFF59E0B);
  static const Color tradeInGoldDark = Color(0xFFD97706);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Alias so both AppColor and AppColors can be used interchangeably
typedef AppColor = AppColors;
