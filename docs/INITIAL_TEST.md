# Initial test (no Redis, Firebase, or Scratchify modal)

You can verify pairing + real API list with **only Django + Flutter**.

## What works without extra services

| Feature | Works? |
|---------|--------|
| Dashboard → My Users → pairing URL + QR | Yes |
| Flutter scan QR → pair with API | Yes |
| Notification list from HeyNotiMe API | Yes (if a row exists in DB) |
| Notification detail → Go to Link | Yes |
| History tab from API | Yes |
| Pull-to-refresh | Yes |
| Scheduled push (Celery) | No — needs Redis — see `E:\Projects\2026\5.May\NotiMe\docs\VPS_REDIS_CELERY.md` |
| Push when app closed (FCM) | No — needs Firebase |
| QR inside Scratchify site | No — needs iframe on Scratchify |

---

## Step 1 — Backend

```powershell
cd E:\Projects\2026\5.May\NotiMe
.\venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Keep this terminal open. Use `http://127.0.0.1:8000` in the browser.

Optional in `.env`:

```env
NOTIME_PUBLIC_BASE_URL=http://127.0.0.1:8000
```

---

## Step 2 — Dashboard user + pairing link

1. Open `http://127.0.0.1:8000/auth/` and log in (dashboard owner).
2. Go to **Dashboard → My Users**.
3. Create a user (username only) → **Save**.
4. Scroll to **My Users** list — copy the **pairing link** (or scan the QR on screen).
5. Link looks like: `http://127.0.0.1:8000/thescratchify/xxxxxxxx/`

---

## Step 3 — One test notification (no Celery)

In a **second** terminal:

```powershell
cd E:\Projects\2026\5.May\NotiMe
python manage.py create_test_notification
```

Or for a specific user:

```powershell
python manage.py create_test_notification --username their_username
```

---

## Step 4 — Flutter app

**Android emulator** (backend on your PC):

```powershell
cd "e:\Projects\2026\5.May\Scratchify-App Task-Poland"
flutter pub get
flutter run --dart-define=NOTIME_API_BASE=http://10.0.2.2:8000 --dart-define=USE_MOCK_DATA=false
```

**Physical device on same Wi‑Fi:** use your PC IP instead of `10.0.2.2`, e.g.:

```powershell
flutter run --dart-define=NOTIME_API_BASE=http://192.168.1.50:8000 --dart-define=USE_MOCK_DATA=false
```

**Nox / APK:** build and install, then ensure the app can reach the PC IP (not `127.0.0.1`).

---

## Step 5 — In the app

1. Tap **Scan QR Code**.
2. Scan the QR from the dashboard (or paste the pairing URL if you add a paste field / use a QR generator app).
3. You should land on the notifications home for Scratchify.
4. You should see **Test notification** (from step 3).
5. Tap it → **Go to Link** opens Scratchify in the browser.

---

## Optional — API check in browser/curl

After pairing, the app stores a token locally. To test the API manually you need the `access_token` from a pair response:

```powershell
curl -X POST http://127.0.0.1:8000/api/v1/pair/ -H "Content-Type: application/json" -d "{\"slug\":\"thescratchify\",\"token\":\"PASTE_TOKEN_FROM_URL\"}"
```

Use the token from the last path segment of the pairing URL.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| No pairing URL on My Users | Restart `runserver`; refresh page; create user again |
| App “invalid QR” | `USE_MOCK_DATA=false` and correct `NOTIME_API_BASE` |
| Emulator can’t reach API | Use `10.0.2.2`, not `localhost` |
| Empty notification list | Run `python manage.py create_test_notification` |
| Still using mock UI | Remove `USE_MOCK_DATA=true` |

---

## UI-only demo (no backend)

```powershell
flutter run --dart-define=USE_MOCK_DATA=true
```

Uses fake data; does not test pairing or API.
