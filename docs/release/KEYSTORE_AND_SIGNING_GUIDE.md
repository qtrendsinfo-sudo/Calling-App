# Telora: Keystore Generation & AAB Signing Guide

This guide details the procedure for generating a production upload key, configuring signing properties, and building the production Android App Bundle (AAB) for Google Play release.

---

## 1. Upload Keystore Generation

Run the following command using the standard Java `keytool` utility to generate your production release upload keystore:

```bash
keytool -genkey -v \
  -keystore telora-upload-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storetype JKS
```

### Prompt Details:
* **Keystore password:** Create a secure, strong passphrase.
* **First and Last Name:** Telora Engineering / Organization Name
* **Organizational Unit:** Mobile App Development
* **Organization:** RLStudio
* **City / State / Country:** Your official business registration location
* **Key password:** Keep identical to the keystore password or specify a separate secure key password.

> **CRITICAL SECURITY NOTE:** Never commit `telora-upload-key.jks` or any `.keystore` / `.jks` file to source control. Ensure it is included in `.gitignore`. Store a secure backup of this keystore in your organization's encrypted vault (e.g., 1Password, Google Cloud Secret Manager).

---

## 2. Release Signing Configuration

The project's `app/build.gradle.kts` is already pre-configured to read signing credentials from environment variables or a local `key.properties` file:

```kotlin
signingConfigs {
    create("release") {
        val keystorePath = System.getenv("KEYSTORE_PATH") ?: "${rootDir}/telora-upload-key.jks"
        storeFile = file(keystorePath)
        storePassword = System.getenv("STORE_PASSWORD")
        keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
        keyPassword = System.getenv("KEY_PASSWORD")
    }
}
```

### Option A: Local `key.properties` Setup (Developer Machine)
Create a file named `key.properties` in the project root (never committed to Git):

```properties
release.keystore.path=/path/to/your/telora-upload-key.jks
release.keystore.password=YOUR_STORE_PASSWORD
release.key.alias=upload
release.key.password=YOUR_KEY_PASSWORD
```

### Option B: CI/CD Environment Variables (GitHub Actions / Cloud Build)
Configure the following secrets in your CI/CD pipeline:
* `KEYSTORE_PATH`: Path to the decrypted keystore file
* `STORE_PASSWORD`: Keystore passphrase
* `KEY_ALIAS`: `upload`
* `KEY_PASSWORD`: Key passphrase

---

## 3. Building the Release AAB (Android App Bundle)

Google Play requires the **AAB (Android App Bundle)** format for all new app releases:

```bash
# Build the production release bundle
gradle :app:bundleRelease
```

The resulting optimized bundle will be generated at:
`app/build/outputs/bundle/release/app-release.aab`

---

## 4. Google Play App Signing Setup

When creating the app in the Google Play Console:
1. Navigate to **Release > Setup > App signing**.
2. Select **Use Google Play App Signing** (recommended).
3. Upload `app-release.aab` signed with your upload key (`telora-upload-key.jks`).
4. Google Play will verify your upload signature, re-sign the APKs with the Google app signing key, and distribute optimized APK splits to user devices.
