import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/utils/validators.dart';
import '../../../../presentation/common_widgets/custom_button.dart';
import '../../../../presentation/common_widgets/custom_text_field.dart';
import '../controllers/auth_controller.dart';

/// Password Update Screen (used for password reset deep links & in-app settings change).
class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onUpdatePressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      try {
        await ref
            .read(authControllerProvider.notifier)
            .updatePassword(_passwordController.text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Your password has been updated successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
        }
      } catch (_) {
        // Errors handled in controller
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Update Password'),
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
                  'Set New Password',
                  style: AppTypography.headlineSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onBackground,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose a secure password with at least 8 characters.',
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
                  controller: _passwordController,
                  labelText: 'New Password',
                  hintText: 'Minimum 8 characters',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.onSurfaceVariant),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: AppSpacing.l),

                CustomTextField(
                  controller: _confirmPasswordController,
                  labelText: 'Confirm New Password',
                  hintText: 'Re-enter your password',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.onSurfaceVariant),
                  validator: (val) => Validators.validateConfirmPassword(val, _passwordController.text),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _onUpdatePressed(),
                ),

                const SizedBox(height: AppSpacing.xl),

                CustomPrimaryButton(
                  text: 'Save Password',
                  isLoading: authState.isLoading,
                  onPressed: authState.isLoading ? null : _onUpdatePressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
