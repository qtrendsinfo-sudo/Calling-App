import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../presentation/common_widgets/telora_button.dart';

/// 3-Screen Premium Onboarding Flow for Telora.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _pages = const [
    _OnboardingItem(
      title: AppStrings.onboarding1Title,
      description: AppStrings.onboarding1Body,
      icon: Icons.public_rounded,
      accentColor: AppColors.primary,
    ),
    _OnboardingItem(
      title: AppStrings.onboarding2Title,
      description: AppStrings.onboarding2Body,
      icon: Icons.graphic_eq_rounded,
      accentColor: AppColors.secondary,
    ),
    _OnboardingItem(
      title: AppStrings.onboarding3Title,
      description: AppStrings.onboarding3Body,
      icon: Icons.security_rounded,
      accentColor: AppColors.tertiary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding(String targetRoute) async {
    await ref.read(onboardingServiceProvider).setOnboardingCompleted();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(targetRoute);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!isLastPage)
            TextButton(
              onPressed: () => _completeOnboarding(AppRoutes.login),
              child: Text(
                AppStrings.skip,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return Padding(
                    padding: AppSpacing.screenPadding,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Stylized Original Abstract Communication Visual
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: item.accentColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: item.accentColor.withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: item.accentColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                item.icon,
                                size: 52,
                                color: item.accentColor,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        Text(
                          item.title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.onBackground,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: AppSpacing.m),

                        Text(
                          item.description,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Pagination Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? AppColors.primary : AppColors.border,
                    borderRadius: AppRadius.round,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l, vertical: AppSpacing.m),
              child: isLastPage
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TeloraButton(
                          text: AppStrings.createAccount,
                          onPressed: () => _completeOnboarding(AppRoutes.signup),
                        ),
                        const SizedBox(height: AppSpacing.m),
                        TeloraOutlinedButton(
                          text: AppStrings.signIn,
                          onPressed: () => _completeOnboarding(AppRoutes.login),
                        ),
                      ],
                    )
                  : TeloraButton(
                      text: AppStrings.continueText,
                      onPressed: _nextPage,
                    ),
            ),
            const SizedBox(height: AppSpacing.s),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}
