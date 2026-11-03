import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../../../presentation/common_widgets/custom_button.dart';
import '../../../../presentation/common_widgets/custom_text_field.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../controllers/profile_controller.dart';
import '../controllers/profile_state.dart';

/// Screen allowing users to update their public profile, avatar, username, and bio.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  File? _selectedImageFile;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileControllerProvider).profile;
    _displayNameController = TextEditingController(text: profile?.displayName ?? '');
    _usernameController = TextEditingController(text: profile?.username ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');

    _displayNameController.addListener(_onFieldChanged);
    _usernameController.addListener(_onUsernameChanged);
    _bioController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  void _onUsernameChanged() {
    _onFieldChanged();
    ref.read(profileControllerProvider.notifier).checkUsernameAvailability(_usernameController.text);
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _selectedImageFile = File(picked.path);
          _hasChanges = true;
        });
      }
    } catch (_) {
      // Permission or cancellation handled gracefully
    }
  }

  Future<void> _onSavePressed() async {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      final controller = ref.read(profileControllerProvider.notifier);

      // Upload avatar first if a new image was selected
      if (_selectedImageFile != null) {
        final bytes = await _selectedImageFile!.readAsBytes();
        final ext = _selectedImageFile!.path.split('.').last;
        final avatarUrl = await controller.uploadAvatar(
          imageBytes: bytes,
          fileExtension: ext,
        );
        if (avatarUrl == null) return; // Error handled inside controller
      }

      final success = await controller.updateProfile(
        displayName: _displayNameController.text,
        username: _usernameController.text,
        bio: _bioController.text,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.profileUpdated),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes that will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Discard',
              style: AppTypography.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.editProfile),
          actions: [
            TextButton(
              onPressed: state.isLoading ? null : _onSavePressed,
              child: Text(
                'Save',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        _selectedImageFile != null
                            ? CircleAvatar(
                                radius: 52,
                                backgroundColor: AppColors.primaryContainer,
                                backgroundImage: FileImage(_selectedImageFile!),
                              )
                            : UserAvatar(
                                avatarUrl: profile?.avatarUrl,
                                displayName: profile?.displayName ?? 'User',
                                radius: 52,
                              ),
                        InkWell(
                          onTap: _pickImage,
                          borderRadius: AppRadius.round,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.s),

                  Center(
                    child: TextButton(
                      onPressed: _pickImage,
                      child: const Text(AppStrings.changePhoto),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Error Banner
                  if (state.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: AppRadius.m,
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              state.errorMessage!,
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

                  // Display Name
                  CustomTextField(
                    controller: _displayNameController,
                    labelText: AppStrings.displayName,
                    hintText: 'Your name',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.onSurfaceVariant),
                    validator: Validators.validateDisplayName,
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Username
                  CustomTextField(
                    controller: _usernameController,
                    labelText: AppStrings.username,
                    hintText: 'e.g. alex_hunter',
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppColors.onSurfaceVariant),
                    validator: Validators.validateUsername,
                    suffixIcon: state.isCheckingUsername
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (!state.isUsernameAvailable
                            ? const Tooltip(
                                message: AppStrings.usernameTaken,
                                child: Icon(Icons.cancel_outlined, color: AppColors.error),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, color: AppColors.success)),
                  ),

                  const SizedBox(height: AppSpacing.l),

                  // Bio Field
                  CustomTextField(
                    controller: _bioController,
                    labelText: AppStrings.bio,
                    hintText: AppStrings.bioHint,
                    maxLines: 3,
                    validator: (val) {
                      if (val != null && val.trim().length > 160) {
                        return 'Bio cannot exceed 160 characters.';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  CustomPrimaryButton(
                    text: AppStrings.save,
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : _onSavePressed,
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
