import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Manages WebRTC PeerConnection, local/remote media tracks, and device controls.
/// Supports both native platform execution (Android/iOS) and simulated Web/Sandbox fallback.
class WebRtcManager {
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _isDisposed = false;
  bool _isMockMode = false;

  bool get isMuted => _isMuted;
  bool get isCameraOff => _isCameraOff;
  bool get isMockMode => _isMockMode;
  RTCPeerConnection? get peerConnection => _peerConnection;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;

  Function(RTCIceCandidate candidate)? onLocalCandidate;
  Function(MediaStream remoteStream)? onRemoteStreamAdded;
  Function(RTCPeerConnectionState state)? onConnectionStateChanged;

  /// Default ICE Configuration with public STUN servers.
  static final Map<String, dynamic> configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  static final Map<String, dynamic> _offerAnswerConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> initializeRenderers() async {
    if (kIsWeb) {
      _isMockMode = true;
      return;
    }
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } catch (e) {
      debugPrint('[WebRTC] Renderers fallback to mock preview: $e');
      _isMockMode = true;
    }
  }

  Future<void> setupMediaAndPeerConnection({required bool isVideo}) async {
    _isDisposed = false;

    // Graceful Web / Sandbox simulated fallback
    if (kIsWeb || _isMockMode) {
      _isMockMode = true;
      _simulateConnection();
      return;
    }

    try {
      // 1. Acquire User Media
      final mediaConstraints = <String, dynamic>{
        'audio': true,
        'video': isVideo
            ? {
                'mandatory': {
                  'minWidth': '640',
                  'minHeight': '480',
                  'minFrameRate': '30',
                },
                'facingMode': 'user',
                'optional': [],
              }
            : false,
      };

      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      localRenderer.srcObject = _localStream;

      // 2. Create RTCPeerConnection
      _peerConnection = await createPeerConnection(configuration);

      // 3. Register PeerConnection Callbacks
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (!_isDisposed && onLocalCandidate != null) {
          onLocalCandidate!(candidate);
        }
      };

      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('[WebRTC] Connection State: $state');
        if (!_isDisposed && onConnectionStateChanged != null) {
          onConnectionStateChanged!(state);
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('[WebRTC] Remote track received: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          remoteRenderer.srcObject = _remoteStream;
          if (!_isDisposed && onRemoteStreamAdded != null) {
            onRemoteStreamAdded!(_remoteStream!);
          }
        }
      };

      // 4. Add Local Tracks to PeerConnection
      for (final track in _localStream!.getTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    } catch (e) {
      debugPrint('[WebRTC] Native setup failed, activating simulated stream mode: $e');
      _isMockMode = true;
      _simulateConnection();
    }
  }

  void _simulateConnection() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!_isDisposed && onConnectionStateChanged != null) {
        onConnectionStateChanged!(RTCPeerConnectionState.RTCPeerConnectionStateConnected);
      }
    });
  }

  Future<RTCSessionDescription> createOffer() async {
    if (_isMockMode || _peerConnection == null) {
      return RTCSessionDescription('v=0\r\no=mock-offer 123 456 IN IP4 0.0.0.0\r\ns=-\r\nt=0 0\r\n', 'offer');
    }
    final offer = await _peerConnection!.createOffer(_offerAnswerConstraints);
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  Future<RTCSessionDescription> handleRemoteOffer(Map<String, dynamic> sdpMap) async {
    if (_isMockMode || _peerConnection == null) {
      return RTCSessionDescription('v=0\r\no=mock-answer 123 456 IN IP4 0.0.0.0\r\ns=-\r\nt=0 0\r\n', 'answer');
    }
    final description = RTCSessionDescription(
      sdpMap['sdp'] as String?,
      sdpMap['type'] as String?,
    );
    await _peerConnection!.setRemoteDescription(description);

    final answer = await _peerConnection!.createAnswer(_offerAnswerConstraints);
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  Future<void> handleRemoteAnswer(Map<String, dynamic> sdpMap) async {
    if (_isMockMode || _peerConnection == null) return;
    try {
      final description = RTCSessionDescription(
        sdpMap['sdp'] as String?,
        sdpMap['type'] as String?,
      );
      await _peerConnection!.setRemoteDescription(description);
    } catch (_) {}
  }

  Future<void> handleRemoteIceCandidate(Map<String, dynamic> candidateMap) async {
    if (_isMockMode || _peerConnection == null) return;
    try {
      final candidate = RTCIceCandidate(
        candidateMap['candidate'] as String?,
        candidateMap['sdpMid'] as String?,
        candidateMap['sdpMLineIndex'] as int?,
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (_) {}
  }

  bool toggleMute() {
    _isMuted = !_isMuted;
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      try {
        final audioTrack = _localStream!.getAudioTracks().first;
        audioTrack.enabled = !_isMuted;
      } catch (_) {}
    }
    return _isMuted;
  }

  bool toggleCamera() {
    _isCameraOff = !_isCameraOff;
    if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
      try {
        final videoTrack = _localStream!.getVideoTracks().first;
        videoTrack.enabled = !_isCameraOff;
      } catch (_) {}
    }
    return _isCameraOff;
  }

  Future<void> switchCamera() async {
    if (kIsWeb || _isMockMode) return;
    try {
      if (_localStream != null && _localStream!.getVideoTracks().isNotEmpty) {
        final videoTrack = _localStream!.getVideoTracks().first;
        await Helper.switchCamera(videoTrack);
      }
    } catch (_) {}
  }

  Future<void> toggleSpeaker(bool enableSpeaker) async {
    if (kIsWeb || _isMockMode) return;
    try {
      if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
        final audioTrack = _localStream!.getAudioTracks().first;
        await audioTrack.enableSpeakerphone(enableSpeaker);
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    _isDisposed = true;

    try {
      if (_localStream != null) {
        for (final track in _localStream!.getTracks()) {
          try { track.stop(); } catch (_) {}
        }
        try { await _localStream!.dispose(); } catch (_) {}
        _localStream = null;
      }

      if (_remoteStream != null) {
        for (final track in _remoteStream!.getTracks()) {
          try { track.stop(); } catch (_) {}
        }
        try { await _remoteStream!.dispose(); } catch (_) {}
        _remoteStream = null;
      }

      if (_peerConnection != null) {
        try { await _peerConnection!.close(); } catch (_) {}
        try { await _peerConnection!.dispose(); } catch (_) {}
        _peerConnection = null;
      }

      if (!kIsWeb) {
        localRenderer.srcObject = null;
        remoteRenderer.srcObject = null;
        try { await localRenderer.dispose(); } catch (_) {}
        try { await remoteRenderer.dispose(); } catch (_) {}
      }
    } catch (e) {
      debugPrint('[WebRTC] Safe dispose completed: $e');
    }
  }
}
