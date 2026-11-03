import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../presentation/common_widgets/custom_button.dart';
import '../../../../presentation/common_widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';
import '../controllers/auth_state.dart';

/// Production Login Screen with client-side validation and Supabase Auth.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AppAuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.l),

                  // Header / Brand Symbol
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.all_inclusive_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  Text(
                    'Welcome back',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onBackground,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    'Sign in to continue to ${AppConstants.appName}',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Error Banner
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: AppSpacing.borderRadiusM,
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              authState.errorMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],

                  // Success Banner (e.g. from password reset confirmation)
                  if (authState.successMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: AppSpacing.borderRadiusM,
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              authState.successMessage!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                  ],

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email Address',
                    hintText: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
                    validator: Validators.validateEmail,
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceVariant),
                    validator: Validators.validatePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _onLoginPressed(),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Forgot Password Action
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).clearMessages();
                        Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      ),
                      child: Text(
                        'Forgot password?',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Sign In Button
                  CustomPrimaryButton(
                    text: 'Sign In',
                    isLoading: authState.isLoading,
                    onPressed: authState.isLoading ? null : _onLoginPressed,
                  ),

                  const SizedBox(height: AppSpacing.m),

                  // Quick Demo Sign In Button for instant web preview inspection
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary),
                      label: const Text('Quick Demo Preview (Sign In as Alice)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: AppSpacing.borderRadiusM),
                      ),
                      onPressed: () {
                        _emailController.text = 'alice@telora.app';
                        _passwordController.text = 'Password123!';
                        _onLoginPressed();
                      },
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Sign Up Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(authControllerProvider.notifier).clearMessages();
                          Navigator.of(context).pushNamed(AppRoutes.signup);
                        },
                        child: Text(
                          'Sign Up',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
