import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../controllers/call_controller.dart';

/// Screen displayed when receiving an incoming voice or video call.
class IncomingCallScreen extends ConsumerWidget {
  final CallEntity call;

  const IncomingCallScreen({super.key, required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caller = call.callerProfile;
    final displayName = caller?.displayName ?? 'Incoming Call';
    final isVideo = call.callType == CallType.video;

    return WillPopScope(
      onWillPop: () async {
        await ref.read(callControllerProvider.notifier).declineCall(call);
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Header
                Column(
                  children: [
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                // Center Caller Info
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryContainer.withOpacity(0.5),
                      ),
                      child: UserAvatar(
                        avatarUrl: caller?.avatarUrl,
                        displayName: displayName,
                        radius: 64,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.l),
                    Text(
                      displayName,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (caller?.username != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${caller!.username}',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                // Bottom Action Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Decline Call (Red)
                      Column(
                        children: [
                          FloatingActionButton(
                            heroTag: 'decline_btn',
                            onPressed: () async {
                              await ref.read(callControllerProvider.notifier).declineCall(call);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: const Icon(Icons.call_end_rounded, size: 28),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            AppStrings.reject,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),

                      // Accept Call (Green)
                      Column(
                        children: [
                          FloatingActionButton(
                            heroTag: 'accept_btn',
                            onPressed: () async {
                              final success = await ref
                                  .read(callControllerProvider.notifier)
                                  .answerCall(call);
                              if (success && context.mounted) {
                                Navigator.of(context).pushReplacementNamed(
                                  AppRoutes.voiceCall,
                                );
                              }
                            },
                            backgroundColor: AppColors.online,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shape: const CircleBorder(),
                            child: Icon(
                              isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            AppStrings.accept,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
