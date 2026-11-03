import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../presentation/common_widgets/user_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/call_controller.dart';

/// Screen managing both Voice and Video active call rendering with controls.
class ActiveCallScreen extends ConsumerWidget {
  const ActiveCallScreen({super.key});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final callState = ref.watch(callControllerProvider);
    final callNotifier = ref.read(callControllerProvider.notifier);
    final currentUserId = ref.watch(currentUserIdProvider) ?? '';
    final call = callState.call;

    // Pop screen if call terminated
    if (callState.status == CallStatus.ended ||
        callState.status == CallStatus.rejected ||
        callState.status == CallStatus.cancelled ||
        callState.status == CallStatus.missed ||
        callState.status == CallStatus.failed ||
        callState.status == CallStatus.busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }

    final otherProfile = call?.getOtherProfile(currentUserId);
    final displayName = otherProfile?.displayName ?? 'Telora User';
    final isVideo = call?.callType == CallType.video;

    return WillPopScope(
      onWillPop: () async {
        await callNotifier.endCall();
        return true;
      },
      child: Scaffold(
        backgroundColor: isVideo ? Colors.black : AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              // Main Visual Content
              if (isVideo)
                _buildVideoLayout(context, callNotifier, callState)
              else
                _buildVoiceLayout(context, displayName, otherProfile?.avatarUrl, callState),

              // Top Bar with Call Status & Duration
              Positioned(
                top: AppSpacing.m,
                left: AppSpacing.m,
                right: AppSpacing.m,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVideo ? Colors.black54 : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      callState.status == CallStatus.connected
                          ? _formatDuration(callState.durationSeconds)
                          : _getStatusText(callState.status),
                      style: AppTypography.titleMedium.copyWith(
                        color: isVideo ? Colors.white : AppColors.onBackground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Control Bar
              Positioned(
                bottom: AppSpacing.l,
                left: 0,
                right: 0,
                child: _buildControls(context, callNotifier, callState, isVideo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(CallStatus status) {
    switch (status) {
      case CallStatus.initiated:
        return 'Connecting...';
      case CallStatus.ringing:
        return 'Ringing...';
      case CallStatus.accepted:
        return 'Establishing connection...';
      case CallStatus.connected:
        return 'Connected';
      case CallStatus.rejected:
        return 'Call Declined';
      case CallStatus.busy:
        return 'User Busy';
      case CallStatus.failed:
        return 'Call Failed';
      case CallStatus.ended:
        return 'Call Ended';
      default:
        return 'Calling...';
    }
  }

  Widget _buildVoiceLayout(
    BuildContext context,
    String displayName,
    String? avatarUrl,
    CallState state,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryContainer.withOpacity(0.4),
            ),
            child: UserAvatar(
              avatarUrl: avatarUrl,
              displayName: displayName,
              radius: 64,
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          Text(
            displayName,
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.onBackground,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            state.status == CallStatus.connected
                ? AppStrings.voiceCall
                : _getStatusText(state.status),
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.m),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
              child: Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoLayout(
    BuildContext context,
    CallController callNotifier,
    CallState state,
  ) {
    final otherProfile = state.call?.getOtherProfile(ref.read(currentUserIdProvider) ?? '');
    final displayName = otherProfile?.displayName ?? 'Telora User';
    final isMock = kIsWeb || callNotifier.webrtcManager.isMockMode;

    if (isMock) {
      return Stack(
        children: [
          // Fullscreen Simulated Remote Video Stream
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Color(0xFF1E293B),
                    Color(0xFF0F172A),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.15),
                        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 2),
                      ),
                      child: UserAvatar(
                        avatarUrl: otherProfile?.avatarUrl,
                        displayName: displayName,
                        radius: 56,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    Text(
                      displayName,
                      style: AppTypography.titleLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, size: 14, color: AppColors.online),
                          SizedBox(width: 6),
                          Text(
                            'Simulated HD Video • Encrypted P2P',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating Local Video Preview (Simulated PiP)
          if (!state.isCameraOff)
            Positioned(
              top: 70,
              right: AppSpacing.m,
              width: 110,
              height: 155,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.6), width: 2),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Stack(
                  children: [
                    const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.face_retouching_natural_rounded, color: Colors.white70, size: 36),
                          SizedBox(height: 4),
                          Text(
                            'Self (HD)',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.online,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return Stack(
      children: [
        // Fullscreen Remote Video View (Native Android)
        Positioned.fill(
          child: state.status == CallStatus.connected
              ? RTCVideoView(
                  callNotifier.webrtcManager.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: AppSpacing.m),
                      Text(
                        _getStatusText(state.status),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
        ),

        // Floating Local Video Preview (Native Android)
        if (!state.isCameraOff)
          Positioned(
            top: 70,
            right: AppSpacing.m,
            width: 110,
            height: 155,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
              ),
              clipBehavior: Clip.antiAlias,
              child: RTCVideoView(
                callNotifier.webrtcManager.localRenderer,
                mirror: true,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    CallController callNotifier,
    CallState state,
    bool isVideo,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Mute Microphone Button
        _buildCircleButton(
          icon: state.isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          isActive: state.isMuted,
          onPressed: callNotifier.toggleMute,
          tooltip: state.isMuted ? 'Unmute' : 'Mute',
        ),

        // Speaker / Earpiece Toggle (Voice call) OR Switch Camera (Video call)
        if (isVideo)
          _buildCircleButton(
            icon: Icons.flip_camera_ios_rounded,
            isActive: false,
            onPressed: callNotifier.switchCamera,
            tooltip: 'Flip Camera',
          )
        else
          _buildCircleButton(
            icon: state.isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
            isActive: state.isSpeakerOn,
            onPressed: callNotifier.toggleSpeaker,
            tooltip: state.isSpeakerOn ? 'Earpiece' : 'Speaker',
          ),

        // Camera Toggle (Video call only)
        if (isVideo)
          _buildCircleButton(
            icon: state.isCameraOff ? Icons.videocam_off_rounded : Icons.videocam_rounded,
            isActive: state.isCameraOff,
            onPressed: callNotifier.toggleCamera,
            tooltip: state.isCameraOff ? 'Turn Camera On' : 'Turn Camera Off',
          ),

        // End Call Button (Red)
        FloatingActionButton(
          heroTag: 'hangup_btn',
          onPressed: () => callNotifier.endCall(),
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: const CircleBorder(),
          child: const Icon(Icons.call_end_rounded, size: 28),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? Colors.white : AppColors.surfaceVariant,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.onSurface,
          size: 26,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
