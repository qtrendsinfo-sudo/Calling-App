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

/// Production Registration Screen with client-side form validation and Supabase Auth.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignupPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text,
            password: _passwordController.text,
            username: _usernameController.text,
            displayName: _displayNameController.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AppAuthState>(authControllerProvider, (previous, next) {
      if (next.isAuthenticated) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
      } else if (next.isVerificationRequired) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.emailVerification,
          arguments: next.email,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.s),

                Text(
                  'Join ${AppConstants.appName}',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  'Connect with friends worldwide with clear voice and video calling.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                ),

                const SizedBox(height: AppSpacing.l),

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

                // Username Field
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                  hintText: 'e.g. alex_hunter',
                  prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.onSurfaceVariant),
                  validator: Validators.validateUsername,
                ),

                const SizedBox(height: AppSpacing.l),

                // Display Name Field
                CustomTextField(
                  controller: _displayNameController,
                  labelText: 'Display Name',
                  hintText: 'e.g. Alex Hunter',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.onSurfaceVariant),
                  validator: Validators.validateDisplayName,
                ),

                const SizedBox(height: AppSpacing.l),

                // Email Address
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
                  hintText: 'Minimum 8 characters',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceVariant),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: AppSpacing.l),

                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.onSurfaceVariant),
                  validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onSignupPressed(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Sign Up Button
                CustomPrimaryButton(
                  text: 'Create Account',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _onSignupPressed,
                ),

                const SizedBox(height: AppSpacing.xl),

                // Navigate back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(authControllerProvider.notifier).clearMessages();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Sign In',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.l),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
