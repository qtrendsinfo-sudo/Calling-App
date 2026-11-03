import 'package:flutter/material.dart';

/// Centralized Border Radius Tokens for Telora.
class AppRadius {
  AppRadius._();

  static const double xsValue = 4.0;
  static const double sValue = 8.0;
  static const double mValue = 12.0;
  static const double lValue = 16.0;
  static const double xlValue = 24.0;
  static const double roundValue = 999.0;

  static const Radius xsRadius = Radius.circular(xsValue);
  static const Radius sRadius = Radius.circular(sValue);
  static const Radius mRadius = Radius.circular(mValue);
  static const Radius lRadius = Radius.circular(lValue);
  static const Radius xlRadius = Radius.circular(xlValue);
  static const Radius roundRadius = Radius.circular(roundValue);

  static const BorderRadius xs = BorderRadius.all(xsRadius);
  static const BorderRadius s = BorderRadius.all(sRadius);
  static const BorderRadius m = BorderRadius.all(mRadius);
  static const BorderRadius l = BorderRadius.all(lRadius);
  static const BorderRadius xl = BorderRadius.all(xlRadius);
  static const BorderRadius round = BorderRadius.all(roundRadius);

  // Special Card & Dialog shapes
  static const BorderRadius card = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius sheet = BorderRadius.vertical(top: Radius.circular(24.0));
  static const BorderRadius button = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius input = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius tag = BorderRadius.all(Radius.circular(6.0));
}
