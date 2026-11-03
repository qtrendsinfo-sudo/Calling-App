import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../presentation/common_widgets/loading_indicator.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';

/// Professional Splash Screen verifying session and onboarding state on boot.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    // Safety fallback: Never trap user on splash if network/backend is delayed
    _fallbackTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _navigate();
      }
    });
  }

  Future<void> _navigate() async {
    final authState = ref.read(authControllerProvider);
    final onboardingCompleted =
        await ref.read(onboardingServiceProvider).isOnboardingCompleted();

    if (!mounted) return;

    if (authState.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (!onboardingCompleted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AppAuthState>(authControllerProvider, (previous, next) {
      if (next.status != AuthStatus.loading && next.status != AuthStatus.initial) {
        _fallbackTimer?.cancel();
        _navigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Telora Geometric Loop Logo Symbol
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.all_inclusive_rounded,
                    size: 54,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // App Name
              Text(
                AppConstants.appName,
                style: AppTypography.headlineMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onBackground,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Tagline
              Text(
                AppConstants.appTagline,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),

              const Spacer(flex: 2),

              const CustomLoadingIndicator(size: 24),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
