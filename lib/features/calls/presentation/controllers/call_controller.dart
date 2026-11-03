import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/services/webrtc_manager.dart';
import '../../../../domain/entities/call_entity.dart';
import '../../../../domain/entities/profile_entity.dart';
import '../../../../domain/entities/signaling_message.dart';
import '../../../../domain/repositories/call_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/call_repository_impl.dart';

class CallState {
  final CallEntity? call;
  final CallStatus status;
  final bool isMuted;
  final bool isCameraOff;
  final bool isSpeakerOn;
  final int durationSeconds;
  final String? errorMessage;

  const CallState({
    this.call,
    this.status = CallStatus.initiated,
    this.isMuted = false,
    this.isCameraOff = false,
    this.isSpeakerOn = false,
    this.durationSeconds = 0,
    this.errorMessage,
  });

  CallState copyWith({
    CallEntity? call,
    CallStatus? status,
    bool? isMuted,
    bool? isCameraOff,
    bool? isSpeakerOn,
    int? durationSeconds,
    String? errorMessage,
  }) {
    return CallState(
      call: call ?? this.call,
      status: status ?? this.status,
      isMuted: isMuted ?? this.isMuted,
      isCameraOff: isCameraOff ?? this.isCameraOff,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      errorMessage: errorMessage,
    );
  }
}

final webrtcManagerProvider = Provider.autoDispose<WebRtcManager>((ref) {
  final manager = WebRtcManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) {
  final repository = ref.watch(callRepositoryProvider);
  final webrtc = ref.watch(webrtcManagerProvider);
  final currentUserId = ref.watch(currentUserIdProvider);
  return CallController(repository, webrtc, currentUserId);
});

final incomingCallStreamProvider = StreamProvider<CallEntity>((ref) {
  final repository = ref.watch(callRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return repository.listenIncomingCalls();
});

class CallController extends StateNotifier<CallState> {
  final CallRepository _repository;
  final WebRtcManager _webrtc;
  final String? _currentUserId;

  StreamSubscription<SignalingMessage>? _signalingSub;
  StreamSubscription<CallStatus>? _statusSub;
  Timer? _durationTimer;
  Timer? _timeoutTimer;

  CallController(this._repository, this._webrtc, this._currentUserId)
      : super(const CallState());

  WebRtcManager get webrtcManager => _webrtc;

  /// Initiates an outgoing call
  Future<bool> startCall({
    required String receiverId,
    required CallType type,
    ProfileEntity? receiverProfile,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    // 1. Request Hardware Permissions
    final hasPermissions = await _requestPermissions(type);
    if (!hasPermissions) {
      state = state.copyWith(
        status: CallStatus.failed,
        errorMessage: 'Microphone and/or camera permission denied.',
      );
      return false;
    }

    try {
      state = state.copyWith(
        status: CallStatus.initiated,
        durationSeconds: 0,
        errorMessage: null,
      );

      // 2. Initialize WebRTC Renderers & Stream
      await _webrtc.initializeRenderers();
      await _webrtc.setupMediaAndPeerConnection(isVideo: type == CallType.video);

      // 3. Create Call record in DB
      final callRecord = await _repository.initiateCall(
        receiverId: receiverId,
        type: type,
      );

      final fullCall = callRecord.copyWith(receiverProfile: receiverProfile);
      state = state.copyWith(call: fullCall, status: CallStatus.ringing);

      // 4. Hook up ICE candidate sender
      _webrtc.onLocalCandidate = (candidate) {
        _repository.sendSignaling(
          SignalingMessage(
            callId: fullCall.id,
            senderId: uid,
            receiverId: receiverId,
            type: SignalingType.iceCandidate,
            payload: candidate.toMap(),
            timestamp: DateTime.now(),
          ),
        );
      };

      // 5. Create & Send WebRTC Offer
      final offer = await _webrtc.createOffer();
      await _repository.sendSignaling(
        SignalingMessage(
          callId: fullCall.id,
          senderId: uid,
          receiverId: receiverId,
          type: SignalingType.offer,
          payload: offer.toMap(),
          timestamp: DateTime.now(),
        ),
      );

      // 6. Listen to incoming signaling and status updates
      _listenSignaling(fullCall.id);
      _listenStatus(fullCall.id);

      // 7. Ringing Timeout (45 seconds)
      _timeoutTimer?.cancel();
      _timeoutTimer = Timer(const Duration(seconds: 45), () {
        if (state.status == CallStatus.ringing || state.status == CallStatus.initiated) {
          endCall(status: CallStatus.missed);
        }
      });

      return true;
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.failed,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      await _cleanup();
      return false;
    }
  }

  /// Answers an incoming call
  Future<bool> answerCall(CallEntity incomingCall) async {
    final uid = _currentUserId;
    if (uid == null) return false;

    final hasPermissions = await _requestPermissions(incomingCall.callType);
    if (!hasPermissions) {
      await declineCall(incomingCall);
      state = state.copyWith(
        status: CallStatus.failed,
        errorMessage: 'Microphone and/or camera permission denied.',
      );
      return false;
    }

    try {
      state = state.copyWith(
        call: incomingCall,
        status: CallStatus.accepted,
        durationSeconds: 0,
        errorMessage: null,
      );

      // 1. Initialize WebRTC
      await _webrtc.initializeRenderers();
      await _webrtc.setupMediaAndPeerConnection(isVideo: incomingCall.callType == CallType.video);

      // 2. Hook up ICE candidate sender
      _webrtc.onLocalCandidate = (candidate) {
        _repository.sendSignaling(
          SignalingMessage(
            callId: incomingCall.id,
            senderId: uid,
            receiverId: incomingCall.callerId,
            type: SignalingType.iceCandidate,
            payload: candidate.toMap(),
            timestamp: DateTime.now(),
          ),
        );
      };

      // 3. Update DB call status to accepted
      await _repository.updateCallStatus(
        callId: incomingCall.id,
        status: CallStatus.connected,
      );

      state = state.copyWith(status: CallStatus.connected);
      _startDurationTimer();

      // 4. Listen to signaling & status updates
      _listenSignaling(incomingCall.id);
      _listenStatus(incomingCall.id);

      return true;
    } catch (e) {
      state = state.copyWith(
        status: CallStatus.failed,
        errorMessage: ErrorHandler.getUserMessage(e),
      );
      await _cleanup();
      return false;
    }
  }

  /// Declines an incoming call
  Future<void> declineCall(CallEntity incomingCall) async {
    try {
      await _repository.sendSignaling(
        SignalingMessage(
          callId: incomingCall.id,
          senderId: _currentUserId ?? '',
          receiverId: incomingCall.callerId,
          type: SignalingType.reject,
          timestamp: DateTime.now(),
        ),
      );
    } catch (_) {}
    try {
      await _repository.updateCallStatus(
        callId: incomingCall.id,
        status: CallStatus.rejected,
      );
    } catch (_) {}
    state = state.copyWith(status: CallStatus.rejected);
    await _cleanup();
  }

  /// Ends the active or ringing call
  Future<void> endCall({CallStatus status = CallStatus.ended}) async {
    final currentCall = state.call;
    if (currentCall != null) {
      try {
        final otherId = currentCall.callerId == _currentUserId
            ? currentCall.receiverId
            : currentCall.callerId;

        await _repository.sendSignaling(
          SignalingMessage(
            callId: currentCall.id,
            senderId: _currentUserId ?? '',
            receiverId: otherId,
            type: SignalingType.hangup,
            timestamp: DateTime.now(),
          ),
        );
      } catch (_) {}
      try {
        await _repository.updateCallStatus(
          callId: currentCall.id,
          status: status,
        );
      } catch (_) {}
    }

    state = state.copyWith(status: status);
    await _cleanup();
  }

  void toggleMute() {
    final isMuted = _webrtc.toggleMute();
    state = state.copyWith(isMuted: isMuted);
  }

  void toggleCamera() {
    final isCameraOff = _webrtc.toggleCamera();
    state = state.copyWith(isCameraOff: isCameraOff);
  }

  Future<void> switchCamera() async {
    await _webrtc.switchCamera();
  }

  Future<void> toggleSpeaker() async {
    final nextSpeakerState = !state.isSpeakerOn;
    await _webrtc.toggleSpeaker(nextSpeakerState);
    state = state.copyWith(isSpeakerOn: nextSpeakerState);
  }

  void _listenSignaling(String callId) {
    _signalingSub?.cancel();
    _signalingSub = _repository.listenSignaling(callId).listen((signal) async {
      try {
        switch (signal.type) {
          case SignalingType.offer:
            if (signal.payload != null) {
              final answer = await _webrtc.handleRemoteOffer(signal.payload!);
              await _repository.sendSignaling(
                SignalingMessage(
                  callId: callId,
                  senderId: _currentUserId ?? '',
                  receiverId: signal.senderId,
                  type: SignalingType.answer,
                  payload: answer.toMap(),
                  timestamp: DateTime.now(),
                ),
              );
            }
            break;

          case SignalingType.answer:
            if (signal.payload != null) {
              await _webrtc.handleRemoteAnswer(signal.payload!);
              _timeoutTimer?.cancel();
              state = state.copyWith(status: CallStatus.connected);
              _startDurationTimer();
            }
            break;

          case SignalingType.iceCandidate:
            if (signal.payload != null) {
              await _webrtc.handleRemoteIceCandidate(signal.payload!);
            }
            break;

          case SignalingType.hangup:
            state = state.copyWith(status: CallStatus.ended);
            await _cleanup();
            break;

          case SignalingType.reject:
            state = state.copyWith(status: CallStatus.rejected);
            await _cleanup();
            break;

          case SignalingType.busy:
            state = state.copyWith(status: CallStatus.busy);
            await _cleanup();
            break;
        }
      } catch (e) {
        debugPrint('[WebRTC] Signaling error: $e');
      }
    });
  }

  void _listenStatus(String callId) {
    _statusSub?.cancel();
    _statusSub = _repository.listenCallStatus(callId).listen((status) {
      if (status == CallStatus.connected && state.status != CallStatus.connected) {
        _timeoutTimer?.cancel();
        state = state.copyWith(status: CallStatus.connected);
        _startDurationTimer();
      } else if (status.name == 'rejected' ||
          status.name == 'cancelled' ||
          status.name == 'ended' ||
          status.name == 'missed' ||
          status.name == 'busy' ||
          status.name == 'failed') {
        state = state.copyWith(status: status);
        _cleanup();
      }
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.status == CallStatus.connected) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      } else {
        timer.cancel();
      }
    });
  }

  Future<bool> _requestPermissions(CallType type) async {
    if (kIsWeb) {
      return true;
    }
    try {
      final micStatus = await Permission.microphone.request();
      if (micStatus != PermissionStatus.granted) {
        return false;
      }

      if (type == CallType.video) {
        final cameraStatus = await Permission.camera.request();
        if (cameraStatus != PermissionStatus.granted) {
          return false;
        }
      }

      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _cleanup() async {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _durationTimer?.cancel();
    _durationTimer = null;
    await _signalingSub?.cancel();
    _signalingSub = null;
    await _statusSub?.cancel();
    _statusSub = null;
    await _webrtc.dispose();
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
}
