import 'package:flutter/material.dart';

/// Centralized Light-First Color System for Telora.
/// Follows Material 3 tonal guidelines with clean high-contrast visibility.
class AppColors {
  AppColors._();

  // Primary Brand Colors (Electric Blue / Modern Global Telecom)
  static const Color primary = Color(0xFF0284C7);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFE0F2FE);
  static const Color onPrimaryContainer = Color(0xFF0369A1);

  // Secondary Brand Colors (Indigo Slate)
  static const Color secondary = Color(0xFF4338CA);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEEF2FF);
  static const Color onSecondaryContainer = Color(0xFF3730A3);

  // Tertiary Accent (Cyan Teal)
  static const Color tertiary = Color(0xFF0D9488);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFCCFBF1);
  static const Color onTertiaryContainer = Color(0xFF115E59);

  // Light Background & Surfaces
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF0F172A); // High-contrast Deep Slate
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF0F172A);
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light Gray Card Fill
  static const Color onSurfaceVariant = Color(0xFF64748B); // Slate Muted Text
  static const Color surfaceContainerHighest = Color(0xFFE2E8F0);

  // Call & Status Specific Accents
  static const Color callConnected = Color(0xFF10B981); // Emerald Active Call
  static const Color callMissed = Color(0xFFEF4444); // Crimson Missed/Failed
  static const Color callIncoming = Color(0xFF0284C7); // Blue Ringing
  static const Color callEnd = Color(0xFFDC2626); // Bright Red End Call

  // Presence Indicators
  static const Color online = Color(0xFF10B981);
  static const Color offline = Color(0xFF94A3B8);
  static const Color away = Color(0xFFF59E0B);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0284C7);
  static const Color divider = Color(0xFFF1F5F9);

  // Functional Feedback
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);

  // Shimmer & Skeleton Loaders
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
