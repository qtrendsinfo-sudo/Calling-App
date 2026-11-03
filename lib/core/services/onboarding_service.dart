import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Manages first-run onboarding completion state using SharedPreferences.
class OnboardingService {
  static const String _keyOnboardingCompleted = 'telora_onboarding_completed_v1';

  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyOnboardingCompleted) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> setOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyOnboardingCompleted, true);
    } catch (_) {
      // Graceful fallback
    }
  }
}
