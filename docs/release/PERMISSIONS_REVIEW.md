# Telora: Production AndroidManifest Permissions Review

This document provides a comprehensive review of all permissions and hardware features declared in `app/src/main/AndroidManifest.xml`, their functional justification, runtime consent behavior, and Google Play compliance.

---

## 1. Declared Permissions Matrix

| Permission | Protection Level | Purpose & Core Feature | Runtime Request Behavior | Google Play Policy Compliance |
| :--- | :--- | :--- | :--- | :--- |
| `android.permission.INTERNET` | Normal | Core network communication with Supabase backend, database synchronization, REST endpoints, and WebRTC peer signaling. | Granted automatically at install time. | Standard requirement. Non-restricted. |
| `android.permission.ACCESS_NETWORK_STATE` | Normal | Connectivity monitoring to detect network loss, switch between Wi-Fi and Cellular, and trigger automatic WebRTC ICE reconnection. | Granted automatically at install time. | Standard requirement. Non-restricted. |
| `android.permission.RECORD_AUDIO` | Dangerous | Capturing microphone audio input for voice and video WebRTC calling. | **Runtime Prompt:** Requested strictly on-demand when the user taps "Voice Call", "Video Call", or "Accept" on an incoming call. | **Compliant:** Audio is streamed directly peer-to-peer via DTLS-SRTP and is never recorded or stored on any server. |
| `android.permission.MODIFY_AUDIO_SETTINGS` | Normal | Switching audio routing between earpiece, loudspeaker, and Bluetooth headsets during active voice/video calls. | Granted automatically at install time. | Standard requirement for telecommunications apps. |
| `android.permission.CAMERA` | Dangerous | Capturing local video feed for one-to-one video calls and profile photo selection. | **Runtime Prompt:** Requested strictly when the user initiates or accepts a video call, or accesses the camera to take a profile photo. Voice calls do **not** trigger or activate the camera. | **Compliant:** Camera streams directly to the peer over WebRTC and is never retained on server infrastructure. |
| `android.permission.POST_NOTIFICATIONS` | Dangerous (Android 13+ / API 33+) | Presenting incoming call alerts, message notifications, and connection requests. | **Runtime Prompt:** Requested gracefully during onboarding or after user completes registration. | Standard requirement for messaging & telecommunications. |
| `android.permission.VIBRATE` | Normal | Providing tactile haptic feedback for incoming ringers, call button taps, and message notifications. | Granted automatically at install time. | Non-restricted. |

---

## 2. Hardware Feature Compatibility (`<uses-feature>`)

To prevent the Google Play Store from filtering out devices that lack dedicated camera hardware, autofocus mechanisms, or specific microphones (such as tablets or specialized Android devices), the following features are explicitly declared as optional:

```xml
<uses-feature android:name="android.hardware.camera" android:required="false" />
<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />
<uses-feature android:name="android.hardware.microphone" android:required="false" />
```

* **Effect:** Devices without a front camera or autofocus can still download Telora to make voice calls and send messages.

---

## 3. Zero Broad Storage Permissions Compliance

* **Google Play Storage Policy:** Telora strictly complies with Google Play's restrictive storage access policies.
* **No `READ_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE`:** Media picking (profile avatars, chat image attachments) utilizes zero-permission system photo pickers (`ActivityResultContracts.PickVisualMedia` / `image_picker`), eliminating the need for broad storage access.
