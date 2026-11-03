import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../../presentation/common_widgets/custom_button.dart';
import '../../../../presentation/common_widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

/// Password Reset Request Screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendResetPressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      try {
        await ref.read(authControllerProvider.notifier).sendPasswordReset(_emailController.text.trim());
        if (mounted) {
          setState(() {
            _isSubmitted = true;
          });
        }
      } catch (_) {
        // Errors are mapped inside AuthController
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: _isSubmitted
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF0FDF4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
                          size: 48,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.l),
                      Text(
                        'Check your email',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        "If an account exists for ${_emailController.text.trim()}, you'll receive instructions to reset your password.",
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      CustomPrimaryButton(
                        text: 'Back to Sign In',
                        onPressed: () => Navigator.of(context).pop(),
                        width: 200,
                      ),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        'Forgot your password?',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Enter your registered email address and we will send you a link to reset your password.',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
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

                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        hintText: 'name@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.onSurfaceVariant),
                        validator: Validators.validateEmail,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onSendResetPressed(),
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      CustomPrimaryButton(
                        text: 'Send Instructions',
                        isLoading: authState.isLoading,
                        onPressed: authState.isLoading ? null : _onSendResetPressed,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
