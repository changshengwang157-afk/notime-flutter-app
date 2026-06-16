# NotiMe (Notime) — Flutter UI prototype

Single Flutter project for the Scratchify / heynotime notification app demo.

**Live API mode** — connects to HeyNotiMe Django (`E:\Projects\2026\5.May\NotiMe`). Use `--dart-define=USE_MOCK_DATA=true` for offline UI demo.

Spec & requirements: [`Scratchify-spec.txt`](Scratchify-spec.txt)  
**v1 scope (client confirmations):** [`docs/v1-scope.md`](docs/v1-scope.md)  
**TestFlight (iOS):** [`docs/TESTFLIGHT_SETUP.md`](docs/TESTFLIGHT_SETUP.md)  
**Firebase push:** [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)

---

## Project layout

```text
Scratchify-App Task-Poland/
├── lib/                 # App source (screens, routing, mock data)
├── android/             # Android build
├── ios/                 # iOS build
├── test/
├── pubspec.yaml
├── Scratchify-spec.txt  # Client requirements
├── docs/v1-scope.md     # v1 scope & client confirmations
├── preview.png          # UI reference
└── README.md
```

Run all Flutter commands from **this folder** (project root).

---

## Screens & flow

| Step | Route | Spec reference |
|------|--------|----------------|
| QR login | `/` | [starter-tab](https://heynotime.com/mobile-preview/starter-tab/) |
| Account not found | `/account-not-found` | Fixed error copy |
| Notifications list | `/home` (tab 1) | [mobile-preview](https://heynotime.com/mobile-preview/) |
| Sent history | `/home` (tab 2) | Admin screenshots §7 |
| Notification detail | `/notification/:id` | [notification-details](https://heynotime.com/mobile-preview/notification-details/) |
| Add app (Option 1) | `/add-app` | Multi-app QR |

### Demo on emulator (Nox / AVD)

1. Orange banner → **workflow guide**
2. **Start demo workflow** → **Log in → notifications list**
3. Tap an active notification → **detail**
4. Bottom **History** tab
5. **Log out** → QR screen again

---

## Setup & run

```bash
cd "E:\Projects\2026\5.May\Scratchify-App Task-Poland"
flutter pub get
flutter devices
flutter run -d <device-id>
```

### Nox (ADB)

```bash
adb connect 127.0.0.1:62025
flutter run -d 127.0.0.1:62025
```

Use Android **9+** on Nox (API 26+). Android 7.1 shows as `unsupported` in `flutter devices`.

### Build APK (install without `flutter run`)

Close **`flutter attach`** / **`flutter run`** and **Nox** first (avoids “file is being used by another process”, Windows errno 32).

**Recommended on Windows** (staging copy avoids errno 32 when Cursor has the project open):

```powershell
# Debug (testing)
.\scripts\build-apk.ps1 -UseStagingCopy -ApiBase "https://heynotime.com" -UseMockData $false

# Release (smaller, faster — same production API)
.\scripts\build-apk.ps1 -UseStagingCopy -Release -ApiBase "https://heynotime.com" -UseMockData $false

adb install -r build\app\outputs\flutter-apk\app-release.apk
```

`build-debug-apk.ps1` is an alias for `build-apk.ps1`.

If you see `Cannot copy file ... notification_*.png` (errno 32): use **`-UseStagingCopy`** above, or close the emulator, Gradle, and PNG tabs in the editor.

**Safe to ignore during build:** `26 packages have newer versions`, `mobile_scanner` / Built-in Kotlin warning, font tree-shaking messages.

**Build errors fixed in this repo:**

- Duplicate `android:label` in `AndroidManifest.xml` (invalid XML).
- Kotlin `different roots` (project on **E:**, Pub cache on **C:**) — `kotlin.incremental=false` in `android/gradle.properties`.

If Kotlin errors persist, move the project to the same drive as Pub cache, e.g. `C:\dev\notime`, or set `PUB_CACHE=E:\pub-cache` and run `flutter pub get` again.

---

## Firebase push (Android)

Push → tap → Scratchify scratch card is implemented in the app. You still need to add Firebase config files:

- **App:** `android/app/google-services.json` — see [`docs/FIREBASE_SETUP.md`](docs/FIREBASE_SETUP.md)
- **Server:** `FCM_SERVICE_ACCOUNT_FILE` on VPS (HeyNotiMe backend)

## Phase 2 (later)

- Store release signing (Play / App Store)
- iOS build + APNs
- Huawei push (non-GMS devices)
