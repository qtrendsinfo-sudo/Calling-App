/// WebRTC Audio/Video constraints and signaling configuration.
class WebRtcConstants {
  WebRtcConstants._();

  // Audio Constraints for optimal VoIP performance (Opus, echo cancellation, AGC, noise suppression)
  static const Map<String, dynamic> audioConstraints = {
    'mandatory': {
      'googEchoCancellation': true,
      'googAutoGainControl': true,
      'googNoiseSuppression': true,
      'googHighpassFilter': true,
    },
    'optional': [],
  };

  // Video Constraints (720p HD balanced for mobile bandwidth & battery)
  static const Map<String, dynamic> videoConstraints = {
    'mandatory': {
      'minWidth': '640',
      'minHeight': '480',
      'idealWidth': '1280',
      'idealHeight': '720',
      'minFrameRate': '15',
      'idealFrameRate': '30',
    },
    'facingMode': 'user',
    'optional': [],
  };

  // Standard SDP Media Constraints for creating offer/answer
  static const Map<String, dynamic> sdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // Audio-only SDP Media Constraints
  static const Map<String, dynamic> audioOnlySdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  // Ringing & Connection Timeouts
  static const Duration ringTimeout = Duration(seconds: 35);
  static const Duration iceConnectionTimeout = Duration(seconds: 15);
}
