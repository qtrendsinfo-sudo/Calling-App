# Telora: Privacy Policy Checklist & AdMob Production Guardrails

This document specifies the required Privacy Policy disclosures and production AdMob monetization guardrails to ensure full compliance with Google Play Developer Program policies and the Better Ads Standards.

---

## 1. Privacy Policy Checklist

A public, active Privacy Policy URL must be submitted in the Google Play Console under **Policy > App content > Privacy Policy**.

### Required Content Clauses:
- [x] **Entity Identification:** State the legal entity/developer name (`RLStudio`).
- [x] **Data Collection Types:** Explicitly enumerate display names, emails, UUIDs, messages, and profile avatars.
- [x] **Real-Time Voice & Video Calling:** Disclose that voice and video calls utilize peer-to-peer WebRTC connections (DTLS-SRTP encryption). Confirm that audio and video streams are ephemeral, streamed directly between participants, and **never recorded, monitored, or stored on servers**.
- [x] **Security & Zero-Trust Access:** Describe Row Level Security (RLS) enforcement ensuring only accepted connections can communicate and blocked users have zero visibility.
- [x] **Third-Party Service Providers:** Disclose infrastructure providers:
  - *Supabase:* Encrypted PostgreSQL database and Realtime signaling
  - *Google Firebase:* Firebase Cloud Messaging (FCM) for push notifications
  - *Google AdMob:* Contextual/personalized advertisement delivery
- [x] **User Rights (GDPR & CCPA):** Disclose right to access, export, correct, and delete personal data.
- [x] **Data Retention & Account Deletion:** Clear instructions on how users can delete their accounts and all associated data.
- [x] **Contact Information:** Provide a dedicated support/privacy email (e.g., `privacy@rlstudio.com`).

---

## 2. Production AdMob Placement Guardrails

To prevent policy strikes and protect the user experience during communications, adhere strictly to the following guardrails:

### A. Prohibited Ad Placements (CRITICAL)
1. **Never Show Ads During Active Calls:**
   - Interstitial, banner, or native ads are **strictly prohibited** on `ActiveCallScreen` or `IncomingCallScreen`.
   - Ad popups during an active voice/video call violate Google Play's *Interfering with Device Functionality* policy.
2. **Never Obscure Emergency or Call Actions:**
   - No ads may be placed near the "End Call", "Accept", or "Decline" buttons where accidental clicks could occur.
3. **No Disruptive Interstitials:**
   - Do not display an interstitial immediately upon app launch or upon switching between conversation tabs.

### B. Permitted Placements
* **Call History Screen:** A standard adaptive banner or native banner ad can be displayed at the bottom of the `CallHistoryTabScreen`.
* **Post-Call Screen (Exit Flow):** If showing an ad after a call has completed, wait until the user has returned to the main screen, and ensure clear close affordances.
* **Conversations Tab:** A native banner ad pinned beneath the conversation list.

### C. Developer Configuration Checklist
1. **`app-ads.txt` Verification:**
   - Host `app-ads.txt` on the root of your developer website (e.g., `https://rlstudio.com/app-ads.txt`).
   - Include your AdMob publisher ID:
     ```
     google.com, pub-XXXXXXXXXXXXXXXX, DIRECT, f08c47fec0942fa0
     ```
2. **COPPA / Child-Directed Settings:**
   - Since Telora is a communication app targeted at users aged 13 and older, configure `tagForChildDirectedTreatment` appropriately in your AdMob initialization code.
3. **Consent Management Platform (CMP / UMP SDK):**
   - For users in the European Economic Area (EEA) and UK, integrate the Google User Messaging Platform (UMP) SDK to gather GDPR consent before requesting personalized ads.
