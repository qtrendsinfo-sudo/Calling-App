import 'package:flutter/material.dart';

/// Centralized Elevation and Soft Shadow Tokens for Telora.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x0A0F172A), // 4% deep slate
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0D0F172A), // 5% deep slate
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> navigation = [
    BoxShadow(
      color: Color(0x0F0F172A), // 6% deep slate
      blurRadius: 20,
      offset: Offset(0, -4),
    ),
  ];

  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color(0x1F0F172A), // 12% deep slate
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> brandGlow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.20),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
