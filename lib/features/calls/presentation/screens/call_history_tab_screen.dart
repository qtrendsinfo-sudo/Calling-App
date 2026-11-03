import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../domain/repositories/call_repository.dart';
import '../../../../presentation/common_widgets/telora_card.dart';
import '../../../../presentation/common_widgets/telora_empty_state.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/call_repository_impl.dart';
import '../controllers/call_controller.dart';

final callHistoryProvider = FutureProvider<List<CallEntity>>((ref) async {
  final repository = ref.watch(callRepositoryProvider);
  return repository.getCallHistory();
});

/// Displays call logs with duration, participant avatars, status indicators, and callback action.
class CallHistoryTabScreen extends ConsumerWidget {
  const CallHistoryTabScreen({super.key});

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return DateFormat.jm().format(time);
    } else if (now.difference(time).inDays < 7) {
      return DateFormat.E().add_jm().format(time);
    } else {
      return DateFormat.MMMd().format(time);
    }
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callHistoryAsync = ref.watch(callHistoryProvider);
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';

    // Listen for incoming calls while the app is active
    ref.listen<AsyncValue<CallEntity>>(incomingCallStreamProvider, (previous, next) {
      next.whenData((incomingCall) {
        if (incomingCall.status == CallStatus.initiated) {
          Navigator.of(context).pushNamed(
            AppRoutes.incomingCall,
            arguments: incomingCall,
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.search, color: AppColors.onSurfaceVariant),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
            tooltip: 'Search people to call',
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(callHistoryProvider.future),
          child: callHistoryAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(
                'Failed to load call history',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
              ),
            ),
            data: (calls) {
              if (calls.isEmpty) {
                return Padding(
                  padding: AppSpacing.screenPadding,
                  child: TeloraEmptyState(
                    icon: AppIcons.callsOutlined,
                    title: AppStrings.emptyCallsTitle,
                    description: AppStrings.emptyCallsDesc,
                    actionText: 'Start a Call',
                    onAction: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
                  ),
                );
              }

              return ListView.separated(
                padding: AppSpacing.screenPadding,
                itemCount: calls.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                itemBuilder: (context, index) {
                  final call = calls[index];
                  final isCaller = call.callerId == currentUserId;
                  final otherProfile = call.getOtherProfile(currentUserId);
                  final displayName = otherProfile?.displayName ?? 'Telora User';
                  final isMissed = call.status == CallStatus.missed || call.status == CallStatus.rejected;
                  final isVideo = call.callType == CallType.video;

                  return TeloraCard(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: 12),
                    child: Row(
                      children: [
                        UserAvatar(
                          avatarUrl: otherProfile?.avatarUrl,
                          displayName: displayName,
                          radius: 24,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isMissed ? AppColors.error : AppColors.onBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    isCaller
                                        ? Icons.call_made_rounded
                                        : (isMissed ? Icons.call_missed_rounded : Icons.call_received_rounded),
                                    size: 14,
                                    color: isMissed
                                        ? AppColors.error
                                        : (call.status == CallStatus.connected
                                            ? AppColors.online
                                            : AppColors.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatTime(call.createdAt),
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  if (call.durationSeconds > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '• ${_formatDuration(call.durationSeconds)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                            color: AppColors.primary,
                          ),
                          tooltip: isVideo ? 'Video Call' : 'Voice Call',
                          onPressed: () async {
                            if (otherProfile == null) return;
                            final success = await ref.read(callControllerProvider.notifier).startCall(
                                  receiverId: otherProfile.id,
                                  type: call.callType,
                                  receiverProfile: otherProfile,
                                );
                            if (success && context.mounted) {
                              Navigator.of(context).pushNamed(
                                isVideo ? AppRoutes.videoCall : AppRoutes.voiceCall,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.userSearch),
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onSecondary,
        elevation: 2,
        tooltip: 'New Call',
        child: const Icon(Icons.add_call, size: 24),
      ),
    );
  }
}
