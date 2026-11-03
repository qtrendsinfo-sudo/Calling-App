# Telora: Google Play Data Safety Disclosures Guide

This document provides the exact questionnaire responses required for completing the **Data Safety** section in the Google Play Console for **Telora** (`com.rlstudio.telora`).

---

## 1. Data Collection & Sharing Overview

* **Does your app collect or share any user data?** `Yes`
* **Is all of the user data collected by your app encrypted in transit?** `Yes` (All data transferred over HTTPS, TLS 1.3, DTLS-SRTP for WebRTC media).
* **Do you provide a way for users to request that their data be deleted?** `Yes` (In-app account deletion under Settings > Privacy, and dedicated web deletion URL).

---

## 2. Data Types & Disclosures Breakdown

### A. Personal Info
1. **Name (Display Name):**
   * *Collected:* Yes
   * *Shared:* Yes (Visible to connected users and in user discovery search).
   * *Purpose:* App functionality, Account management.
   * *Ephemeral:* No.
   * *Optional or Required:* Required.

2. **Email Address:**
   * *Collected:* Yes
   * *Shared:* No (Private to the user and authentication backend).
   * *Purpose:* App functionality, Account management, Security/Fraud prevention.
   * *Ephemeral:* No.
   * *Optional or Required:* Required.

3. **User IDs (UUID):**
   * *Collected:* Yes
   * *Shared:* Yes (Used as database primary keys for messaging and call signaling).
   * *Purpose:* App functionality, Account management.
   * *Ephemeral:* No.
   * *Optional or Required:* Required.

### B. Messages
1. **In-app Messages:**
   * *Collected:* Yes (Stored in encrypted database for persistent chat between connected users).
   * *Shared:* Shared only between the participants of the conversation.
   * *Purpose:* App functionality.
   * *Ephemeral:* No.
   * *Optional or Required:* Optional (User-generated content).

### C. Voice or Sound Recordings (Audio)
1. **Voice Recordings / Live Audio:**
   * *Collected:* **No.**
   * *Details:* Live audio during voice calls is streamed directly peer-to-peer between devices using WebRTC (DTLS-SRTP). Audio data is **ephemeral in transit** and is **never recorded, stored, or processed on server disks**.

### D. Photos and Videos
1. **Photos (Profile Avatars):**
   * *Collected:* Yes (Stored in Supabase Storage if user uploads an avatar).
   * *Shared:* Yes (Visible to other users on profiles).
   * *Purpose:* App functionality, Personalization.
   * *Ephemeral:* No.
   * *Optional or Required:* Optional.

2. **Videos (Live Video Feeds):**
   * *Collected:* **No.**
   * *Details:* Video frames are streamed peer-to-peer over WebRTC directly to the call counterparty. No video is recorded or stored on any server.

### E. App Activity & Performance
1. **Diagnostics / Crash Logs:**
   * *Collected:* Optional (Anonymous crash telemetry).
   * *Purpose:* Analytics, Developer communications.
   * *Ephemeral:* Yes.

### F. Device or Other Identifiers
1. **Device Tokens (FCM Push Tokens):**
   * *Collected:* Yes
   * *Shared:* Shared only with Firebase Cloud Messaging infrastructure to route notifications.
   * *Purpose:* App functionality (delivering incoming call and message alerts).
   * *Ephemeral:* No.

---

## 3. Account Deletion Disclosure & URL

Google Play requires apps that allow account creation to provide both an in-app deletion option and an external web URL where users can request account and data deletion:

* **In-App Deletion Path:** `Settings > Privacy & Security > Delete Account`
* **Web Deletion URL:** `https://telora.rlstudio.com/delete-account` (or your registered support domain)
* **What Data is Deleted:**
  - Profile metadata (`profiles` record)
  - All direct messages sent by the user (`messages` table)
  - All friendships & requests (`user_connections` table)
  - Call history logs (`calls` table)
  - Push notification tokens (`device_tokens` table)
  - Authentication record in `auth.users`
