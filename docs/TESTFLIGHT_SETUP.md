# TestFlight setup (NotiMe iOS)

Everything implemented in the repo for iPhone testing. You still need **Apple Developer access** and a **Mac** to build and upload.

---

## What is already in the repo

| Item | Location |
|------|----------|
| Camera permission text | `ios/Runner/Info.plist` → `NSCameraUsageDescription` |
| Push background mode | `ios/Runner/Info.plist` → `UIBackgroundModes` |
| Associated Domains + Push | `ios/Runner/Runner.entitlements` |
| Runtime camera request | `lib/services/camera_permission.dart` |
| Embed QR URL parsing | `lib/api/notime_api_client.dart` (`/embed/{slug}/{token}`) |
| Universal link listener | `lib/services/deep_link_service.dart` |
| iOS foreground push UI | `lib/services/push_service.dart` |
| App display name **NotiMe** | `ios/Runner/Info.plist` |
| Firebase iOS template | `ios/Runner/GoogleService-Info.plist.example` |
| IPA export template | `ios/ExportOptions.plist` |
| App icons generator | `pubspec.yaml` → `flutter_launcher_icons` |

---

## 1. Apple Developer account

1. Enroll: [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
2. Note your **Team ID** (10 characters): [developer.apple.com/account](https://developer.apple.com/account) → **Membership details**.

### 1a. Register Bundle ID **before** “New App”

App Store Connect only shows bundle IDs that are **already registered**. If the dropdown is empty, do this first:

1. Open [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list).
2. **Identifiers** → **+** (blue button).
3. Select **App IDs** → **Continue**.
4. Type: **App** → **Continue**.
5. Fill in:
   - **Description:** `NotiMe`
   - **Bundle ID:** **Explicit** → `com.heynotime.notimeApp` (must match Xcode in this repo).
6. Capabilities (recommended for NotiMe):
   - **Push Notifications**
   - **Associated Domains** (for `applinks:heynotime.com`)
7. **Register** → **Continue** → **Register**.

Wait 1–2 minutes, then return to App Store Connect → **New App** — the bundle ID should appear in the dropdown.

### 1b. Create app in App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → **New App**.
2. Use these values (do **not** put the bundle ID in the Name field):

| Field | Value |
|-------|--------|
| **Platforms** | **iOS** only (unless you also ship macOS) |
| **Name** | `NotiMe` (user-facing name; max 30 chars) |
| **Primary Language** | English (U.S.) |
| **Bundle ID** | `com.heynotime.notimeApp` (from dropdown after step 1a) |
| **SKU** | `notime-app-001` (any unique string; never shown to users) |
| **User Access** | Full Access |

---

## 2. Firebase iOS

1. [Firebase Console](https://console.firebase.google.com/) → project **notimeapp-54425**.
2. **Add app** → **iOS**.
3. Bundle ID: **`com.heynotime.notimeApp`**.
4. Download **`GoogleService-Info.plist`**.
5. Copy to:

   ```text
   Notime-App/ios/Runner/GoogleService-Info.plist
   ```

6. In Xcode: open `ios/Runner.xcworkspace` → drag `GoogleService-Info.plist` into **Runner** target (Copy items if needed, add to target **Runner**).
7. Firebase → **Project settings** → **Cloud Messaging** → **Apple app configuration**:
   - Upload **APNs Authentication Key** (.p8) from Apple Developer → Keys.

---

## 3. Backend (VPS `.env`)

Add to `/home/app/app/.env` on [heynotime.com](https://heynotime.com):

```env
APPLE_TEAM_ID=YOUR_10_CHAR_TEAM_ID
IOS_BUNDLE_ID=com.heynotime.notimeApp
ANDROID_PACKAGE_NAME=com.heynotime.notime_app
ANDROID_SHA256_CERT_FINGERPRINTS=AA:BB:CC:...   # optional, for Android App Links
FCM_SERVICE_ACCOUNT_FILE=/home/app/app/secrets/firebase-service-account.json
```

Restart Django + Celery after deploy.

Verify universal links:

```bash
curl -s https://heynotime.com/.well-known/apple-app-site-association
```

Should show `"appID": "YOUR_TEAM_ID.com.heynotime.notimeApp"`.

---

## 4. Generate app icons (on any OS)

```bash
cd Notime-App
flutter pub get
dart run flutter_launcher_icons
```

Requires `assets/images/notime_logo.png`.

---

## 5. Build on Mac

```bash
cd Notime-App
flutter pub get
cd ios && pod install && cd ..

flutter build ipa --release \
  --dart-define=NOTIME_API_BASE=https://heynotime.com \
  --dart-define=USE_MOCK_DATA=false \
  --export-options-plist=ios/ExportOptions.plist
```

### Xcode signing (first time)

1. Open `ios/Runner.xcworkspace`.
2. **Runner** target → **Signing & Capabilities**.
3. Team: client’s Apple team.
4. Enable **Push Notifications** and **Associated Domains** (`applinks:heynotime.com`) if not already present.
5. Bundle Identifier: `com.heynotime.notimeApp`.

---

## 6. Upload to TestFlight

**Option A — Xcode:** Window → Organizer → Distribute App → App Store Connect.

**Option B — Transporter app:** Upload `build/ios/ipa/*.ipa`.

**Option C — CLI:**

```bash
xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD
```

---

## 7. TestFlight testers

1. App Store Connect → your app → **TestFlight**.
2. Wait for build processing (15 min – 48 h).
3. **Internal testing** — add team members (fastest).
4. **External testing** — add emails + privacy policy URL (required).

Install **TestFlight** app on iPhone → open invite link.

---

## 8. Test checklist on iPhone

- [ ] Scan fresh QR from Dashboard → My Users (not expired token)
- [ ] Notifications list loads from API
- [ ] Tap notification → **Go to Link** → Scratchify with `?user=`
- [ ] History tab shows sent items
- [ ] Push notification (background) — after APNs + FCM iOS setup
- [ ] Tap push → opens scratch card link

---

## Cannot be done from Windows alone

- `flutter build ipa` / Xcode archive
- Upload to App Store Connect
- Creating APNs key (Apple Developer website)

Use a Mac, MacStadium, GitHub Actions `macos-latest`, or Codemagic.

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| App closes when opening QR scanner | Rebuild with **camera + ML Kit** scanner (build `0.1.0+4+`). On Mac: `cd ios && rm -rf Pods Podfile.lock && pod install`. Uses `ResolutionPreset.high` for iPhone 17 Pro. |
| Paste pairing URL | Fallback on starter screen if camera still fails on a specific device |
| Camera doesn’t open | Settings → NotiMe → Camera ON |
| Invalid QR | Fresh pairing link; slug must match URL (`thescratchify-5`) |
| No push on iOS | `GoogleService-Info.plist` + APNs key in Firebase + entitlements |
| Universal link opens Safari | `APPLE_TEAM_ID` on VPS; reinstall app after AASA deploy |
| Missing 1024 icon | Run `dart run flutter_launcher_icons` |

See also: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md), [`NotiMe-web/docs/MOBILE_API.md`](../NotiMe-web/docs/MOBILE_API.md).
