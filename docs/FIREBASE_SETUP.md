# Firebase push setup (NotiMe — Android + iOS)

End-to-end push: **HeyNotiMe server → FCM → phone tray → tap → Scratchify scratch card**.

You must complete both **server** and **app** steps before push E2E works.

**TestFlight (iOS):** see [`TESTFLIGHT_SETUP.md`](TESTFLIGHT_SETUP.md).

---

## 1. Firebase project apps

### Android

1. Open [Firebase Console](https://console.firebase.google.com/) → project **notimeapp-54425** (or create one).
2. Add an **Android app** with package name:

   ```text
   com.heynotime.notime_app
   ```

3. Download **`google-services.json`** → `Notime-App/android/app/google-services.json`
4. Rebuild the APK (Gradle plugin applies automatically when the file exists).

### iOS (TestFlight / App Store)

1. Same Firebase project → **Add app** → **iOS**.
2. Bundle ID:

   ```text
   com.heynotime.notimeApp
   ```

3. Download **`GoogleService-Info.plist`** → `Notime-App/ios/Runner/GoogleService-Info.plist`
4. Add the file to the **Runner** target in Xcode (see `GoogleService-Info.plist.example`).
5. Firebase → **Cloud Messaging** → upload **APNs Authentication Key** (.p8) from Apple Developer.

---

## 2. Server FCM (VPS)

1. Firebase Console → **Project settings** → **Service accounts** → **Generate new private key**.
2. Save on VPS, e.g. `/home/app/app/secrets/firebase-service-account.json`
3. In `/home/app/app/.env`:

   ```env
   FCM_SERVICE_ACCOUNT_FILE=/home/app/app/secrets/firebase-service-account.json
   APPLE_TEAM_ID=YOUR_10_CHAR_TEAM_ID
   IOS_BUNDLE_ID=com.heynotime.notimeApp
   ```

4. Restart Django + Celery worker + beat.

Universal links (pairing URLs open the app):

```bash
curl -s https://heynotime.com/.well-known/apple-app-site-association
```

## 3. What the app does (implemented)

| Event | Behaviour |
|-------|-----------|
| After QR login | Registers FCM token via `POST /api/v1/devices/` |
| App in background / closed | System notification from FCM |
| App in foreground | Local notification banner (`flutter_local_notifications`) |
| User taps notification | Fetches delivery → opens Scratchify URL with `?user={token}` → marks link clicked |

FCM data payload from server: `delivery_id`, `integration_slug`.

---

## 4. Build & test

```powershell
cd "E:\Projects\2026\5.May\Scratchify-App Task-Poland\Notime-App"
flutter pub get
.\scripts\build-apk.ps1 -UseStagingCopy -Release -ApiBase "https://heynotime.com" -UseMockData $false
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

**Test flow**

1. Install APK on a **Google Play Services** Android device (FCM required).
2. Scan QR from HeyNotiMe dashboard (My Users).
3. On VPS, trigger a test push:

   ```bash
   sudo -u app -H bash -lc 'cd /home/app/app && /home/app/bin/python manage.py create_test_notification --username USERNAME'
   ```

4. Confirm push appears in the tray (foreground and background).
5. Tap push → browser opens Scratchify scratch card with `?user=` in the URL.

---

## 5. Troubleshooting

| Symptom | Check |
|---------|--------|
| No push at all | `FCM_SERVICE_ACCOUNT_FILE` on VPS; Celery logs; device has GMS |
| App builds but no FCM token | `google-services.json` present; package name matches |
| Push arrives, tap does nothing | User still logged in; `delivery_id` in FCM data; API reachable |
| Foreground: no banner | Android 13+ notification permission; iOS: notification permission on first launch |
| No push on iPhone | `GoogleService-Info.plist` + APNs key in Firebase + TestFlight build |
| Huawei without GMS | FCM not supported — needs separate push SDK (out of v1 scope) |

---

## 6. Security

- **Never commit** `google-services.json` or the service-account JSON (both are gitignored / kept in `secrets/` on VPS).
- Rotate keys if they were ever committed to a public repo.
