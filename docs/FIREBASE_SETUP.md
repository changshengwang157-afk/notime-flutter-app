# Firebase push setup (NotiMe Android)

End-to-end push: **HeyNotiMe server → FCM → phone tray → tap → Scratchify scratch card**.

You must complete both **server** and **app** steps before push E2E works.

---

## 1. Create Firebase project

1. Open [Firebase Console](https://console.firebase.google.com/).
2. Create a project (or reuse an existing one).
3. Add an **Android app** with package name:

   ```text
   com.heynotime.notime_app
   ```

4. Download **`google-services.json`**.
5. Copy it to:

   ```text
   Notime-App/android/app/google-services.json
   ```

   (Template: `android/app/google-services.json.example`)

6. Rebuild the APK. The Gradle plugin applies automatically when that file exists.

---

## 2. Server FCM (VPS)

1. Firebase Console → **Project settings** → **Service accounts**.
2. **Generate new private key** → save JSON on VPS, e.g.:

   ```text
   /home/app/app/secrets/firebase-service-account.json
   ```

3. In `/home/app/app/.env`:

   ```env
   FCM_SERVICE_ACCOUNT_FILE=/home/app/app/secrets/firebase-service-account.json
   ```

4. Restart Celery worker + beat so scheduled pushes use the new credential.

---

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
| Foreground: no banner | Android 13+ notification permission; channel `notime_push` |
| Huawei without GMS | FCM not supported — needs separate push SDK (out of v1 scope) |

---

## 6. Security

- **Never commit** `google-services.json` or the service-account JSON (both are gitignored / kept in `secrets/` on VPS).
- Rotate keys if they were ever committed to a public repo.
