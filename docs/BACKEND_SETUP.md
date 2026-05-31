# HeyNotiMe backend (Django)

Code: **`E:\Projects\2026\5.May\NotiMe`**

**Minimal test (no Redis / Firebase / Scratchify):** [`INITIAL_TEST.md`](INITIAL_TEST.md)

Full API and Celery docs: [NotiMe/docs/MOBILE_API.md](file:///E:/Projects/2026/5.May/NotiMe/docs/MOBILE_API.md)

## Quick test with Flutter

1. `python manage.py runserver 0.0.0.0:8000` (Redis/Celery not required for pairing + list).
2. Dashboard → My Users → create user → copy pairing URL.
3. `python manage.py create_test_notification` — one row for the list.
4. Run app:

```powershell
flutter run --dart-define=NOTIME_API_BASE=http://10.0.2.2:8000 --dart-define=USE_MOCK_DATA=false
```

5. Scan QR or paste URL from dashboard.

Mock mode (no server):

```powershell
flutter run --dart-define=USE_MOCK_DATA=true
```
