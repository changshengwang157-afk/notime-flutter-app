# HeyNotiMe backend (Django)

Code: **`E:\Projects\2026\5.May\NotiMe`**

Full API and Celery docs: [NotiMe/docs/MOBILE_API.md](file:///E:/Projects/2026/5.May/NotiMe/docs/MOBILE_API.md)

## Quick test with Flutter

1. Start Redis, Django, Celery (see MOBILE_API.md).
2. `python manage.py seed_notime` — creates `thescratchify` integration.
3. Dashboard → My Users → create user → copy pairing URL.
4. Run app:

```powershell
flutter run --dart-define=NOTIME_API_BASE=http://10.0.2.2:8000 --dart-define=USE_MOCK_DATA=false
```

5. Scan QR or paste URL from dashboard.

Mock mode (no server):

```powershell
flutter run --dart-define=USE_MOCK_DATA=true
```
