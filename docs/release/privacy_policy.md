# Privacy Policy for Telora

**Last Updated:** November 3, 2026  
**Effective Date:** November 3, 2026  
**Application:** Telora (`com.rlstudio.telora`)  
**Developer / Publisher:** RLStudio ("we", "us", or "our")  
**Contact Email:** privacy@rlstudio.com  

---

## 1. Introduction

Welcome to **Telora**, a secure real-time communication platform designed to connect people globally through voice calling, video calling, and instant messaging. Your privacy and data security are foundational to how we build and operate our service.

This Privacy Policy explains how Telora collects, uses, stores, shares, and protects your personal information when you use our Android application, services, and associated websites. It also explains your privacy rights and how you can manage or delete your data.

By creating an account or using Telora, you agree to the collection and use of information in accordance with this Privacy Policy. If you do not agree, please do not access or use our services.

---

## 2. Information We Collect

We collect only the minimum information necessary to provide, secure, and improve our communication features:

### A. Account & Profile Information
* **Authentication Credentials:** Your email address and encrypted password credentials (managed securely through our authentication infrastructure).
* **Profile Metadata:** Your chosen display name, unique `@username`, and optional profile avatar image.
* **Unique User Identifiers:** A system-generated Universally Unique Identifier (UUID) assigned to your account to route messages and calls.

### B. Communication & Social Features
* **User Connections & Friendships:** Records of accepted connections and pending connection requests between you and other users.
* **Block & Safety Lists:** Records of users you have blocked to ensure zero-visibility and prevent unwanted calls or messages.
* **Chat Messages:** Text messages, emojis, and timestamps exchanged with your accepted connections.
* **Call Log History:** Call metadata including caller and receiver user IDs, call type (voice or video), timestamps, status (e.g., connected, missed, rejected), and elapsed call duration.

### C. Real-Time Audio & Video Media (WebRTC)
* **Peer-to-Peer Media Streams:** Live microphone audio and camera video streams during calls are transmitted directly peer-to-peer between participants using industry-standard WebRTC protocols secured by Datagram Transport Layer Security (DTLS) and Secure Real-time Transport Protocol (SRTP).
* **ZERO AUDIO/VIDEO RECORDING:** **We do not record, monitor, listen to, inspect, or store your voice calls or video streams on any server disk.** Live media streams exist purely ephemerally in transit between your device and your call counterparty.

### D. Device, Network & Technical Data
* **Device Push Notification Tokens:** Firebase Cloud Messaging (FCM) registration tokens used to deliver incoming call ringers and new message notifications when your app is not open on the screen.
* **Network & Connectivity Status:** Basic network state indicators (Wi-Fi vs. Cellular) to detect disconnections, manage peer-to-peer ICE candidates, and facilitate seamless reconnection.
* **Diagnostics & Error Logs:** Anonymous crash logs and diagnostic telemetry used to fix app instability and bugs.

---

## 3. How We Use Your Information

We process your data strictly for legitimate operational purposes:

1. **Core Service Delivery:** To authenticate your account, connect you with your contacts, deliver real-time messages, and negotiate one-to-one voice and video calls.
2. **Access Control & Safety Enforcement:** To enforce our strict relationship rules: ensuring only accepted connections can initiate calls or messages, and enforcing bidirectional blocking to completely prevent contact from blocked users.
3. **Notification Delivery:** To wake your device and display caller alerts when an incoming voice/video call or message arrives.
4. **Security & Fraud Prevention:** To protect against spam, abuse, unauthorized account access, and service attacks.
5. **Customer Support:** To investigate and resolve technical issues reported by you.

---

## 4. Data Storage, Security & Retention

### A. Zero-Trust Database Architecture & Encryption
* **Database Row Level Security (RLS):** All data stored in our PostgreSQL backend (Supabase) is guarded by strict Row Level Security policies. Users can only access messages, call history, and profile data for which they are explicit, verified participants.
* **Encryption in Transit:** All network traffic between the Telora app and our servers is encrypted using Transport Layer Security (TLS 1.3 / HTTPS). Live peer-to-peer audio and video media are encrypted end-to-end via DTLS-SRTP.
* **Ephemeral Call Signaling:** Temporary WebRTC signaling records (SDP offers, answers, and ICE candidate exchanges) are retained only while a call is active. When a call terminates (ended, declined, missed, or timed out), all associated signaling rows are automatically purged from the database.

### B. Data Retention
* **Active Accounts:** We retain your profile, connections, chat history, and call logs as long as your account remains active.
* **Historical Call Logs:** Past call history is retained as a personal communication log for your records. If you remove a connection, past logs remain visible for audit purposes, but neither party can start a new call without reconnecting. If either user blocks the other, all shared call history is immediately hidden.

---

## 5. Third-Party Service Providers

We do not sell, rent, or trade your personal data. We partner only with vetted third-party service providers that adhere to strict data security standards:

* **Supabase Inc.:** Cloud database, authentication, and real-time synchronization infrastructure. Data is hosted in secure, ISO 27001 and SOC 2 certified data centers.
* **Google Firebase (Google LLC):** Firebase Cloud Messaging (FCM) for routing push notifications and device tokens.
* **Google AdMob (Google LLC):** Advertising infrastructure for non-intrusive monetization. We adhere to Google Play Better Ads Standards: **ads are strictly forbidden and never displayed during active calls or on call response screens.**
* **WebRTC STUN Relays (Google LLC):** Public Session Traversal Utilities for NAT (STUN) servers used exclusively to discover public IP/port bindings for peer-to-peer call setup. STUN servers process only network socket headers and have zero access to audio or video content.

---

## 6. Permissions & Hardware Access

Telora requests only the permissions strictly required to perform its core functions:

* **Microphone (`android.permission.RECORD_AUDIO`):** Required to capture voice audio during calls. Requested at runtime only when starting or answering a call.
* **Camera (`android.permission.CAMERA`):** Required to capture video during video calls. Requested at runtime only for video calling or capturing an avatar photo. Voice-only calls never access or activate the camera.
* **Notifications (`android.permission.POST_NOTIFICATIONS`):** Required on Android 13+ to notify you of incoming calls and messages.
* **Zero Broad Storage Access:** Telora uses Android's native, zero-permission Photo Picker. We do **not** request or require `READ_EXTERNAL_STORAGE` or `MANAGE_EXTERNAL_STORAGE`.

---

## 7. Your Data Rights & Account Deletion

You maintain full ownership and control over your personal data:

### A. Rights Under GDPR (EEA/UK) and CCPA/CPRA (California)
Depending on your location, you have the right to:
* **Access:** Request a copy of the personal data we hold about you.
* **Rectify:** Update or correct inaccurate profile information directly in the app.
* **Object / Restrict:** Restrict or object to certain types of processing.
* **Data Portability:** Receive your data in a structured, machine-readable format.
* **Erasure ("Right to be Forgotten"):** Request the complete deletion of your account and all associated personal data.

### B. Account Deletion Instructions
You can permanently delete your account and all associated data at any time through either of the following methods:

1. **In-App Deletion:**
   * Open Telora and navigate to **Settings > Privacy & Security > Delete Account**.
   * Confirm your identity and confirm deletion.
2. **Web Request:**
   * Visit our dedicated account deletion portal: `https://telora.rlstudio.com/delete-account`
   * Submit your registered email address to receive a secure verification link.

**What Happens Upon Deletion:**
* Your profile, display name, username, and avatar are permanently erased.
* All your messages, connections, block entries, and call logs are deleted from database tables.
* Your authentication record and credentials are deleted immediately and irreversibly.

---

## 8. Children's Privacy (COPPA Compliance)

Telora is not directed toward children under the age of 13 (or under 16 in certain European jurisdictions). We do not knowingly collect or solicit personal information from children under 13.

If we learn that we have inadvertently collected personal data from a child under 13 without verified parental consent, we will take immediate steps to delete that information from our servers. If you believe a child under 13 has provided us with personal information, please contact us immediately at `privacy@rlstudio.com`.

---

## 9. Changes to this Privacy Policy

We may update this Privacy Policy from time to time to reflect improvements in our features, security practices, or legal requirements. When changes are made, we will update the "Last Updated" date at the top of this document.

For significant changes, we will notify you through an in-app notice, banner, or email before the changes become effective. Your continued use of Telora after any modifications signifies your acceptance of the revised Privacy Policy.

---

## 10. Contact Us

If you have any questions, concerns, or requests regarding this Privacy Policy, your personal data, or our security practices, please contact our Data Protection Officer at:

* **Email:** privacy@rlstudio.com  
* **Developer:** RLStudio  
* **Mailing Address:** RLStudio Legal & Privacy Dept., Global Operations Center  
* **Website:** https://telora.rlstudio.com
