# NotiMe (Notime) — Flutter UI prototype

Single Flutter project for the Scratchify / heynotime notification app demo.

**Mock data only** — no Django API, Celery, FCM, or Firebase in this phase.

Spec & requirements: [`Scratchify-spec.txt`](Scratchify-spec.txt)  
**v1 scope (client confirmations):** [`docs/v1-scope.md`](docs/v1-scope.md)

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

**Recommended on Windows:**

```powershell
.\scripts\build-debug-apk.ps1
adb -s 127.0.0.1:62025 install -r build\app\outputs\flutter-apk\app-debug.apk
```

Manual steps if the script still fails:

```powershell
cd android; .\gradlew.bat --stop; cd ..
flutter clean
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --debug
```

If you see `Cannot copy file ... notime_logo.png` / `notification_*.png` (errno 32): another process locked assets during the build — close the emulator, stop Gradle (`gradlew --stop`), close open PNG tabs in the editor, add a **Windows Defender exclusion** for the project folder, wait a few seconds, then run the script again.

**Build errors fixed in this repo:**

- Duplicate `android:label` in `AndroidManifest.xml` (invalid XML).
- Kotlin `different roots` (project on **E:**, Pub cache on **C:**) — `kotlin.incremental=false` in `android/gradle.properties`.

If Kotlin errors persist, move the project to the same drive as Pub cache, e.g. `C:\dev\notime`, or set `PUB_CACHE=E:\pub-cache` and run `flutter pub get` again.

---

## Phase 2 (later)

- Django REST API + real QR from heynotime.com
- FCM + Celery push
- Secure token storage
- Store release (App Store / Play)
