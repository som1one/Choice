# Local Testing Guide

## Stack

- Backend database: `D:\PycharmProjects\androidapp\backend_fastapi\choice.db`
- Backend services: `http://127.0.0.1:8001` .. `http://127.0.0.1:8008`
- Frontend URL: `http://127.0.0.1:3000`

## One-time setup

1. Backend venv must exist at `D:\PycharmProjects\androidapp\backend_fastapi\venv`.
2. Flutter SDK must be available in `PATH`.
3. RabbitMQ is not required for this local stack.

## Start backend locally

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\PycharmProjects\androidapp\backend_fastapi\start_local_services.ps1
```

What it does:

- forces SQLite with `backend_fastapi\choice.db`
- disables RabbitMQ with `RABBITMQ_ENABLED=false`
- starts all 8 FastAPI services
- writes logs to `D:\PycharmProjects\androidapp\backend_fastapi\etc\local_logs`

## Start Flutter locally

Run:

```powershell
powershell -ExecutionPolicy Bypass -File D:\PycharmProjects\androidapp\client_app_flutter\start_local_web.ps1
```

This starts Flutter web on `http://127.0.0.1:3000` and points it to the local backend.

Logs:

- `D:\PycharmProjects\androidapp\client_app_flutter\build_artifacts\local_logs\flutter-web.out.log`
- `D:\PycharmProjects\androidapp\client_app_flutter\build_artifacts\local_logs\flutter-web.err.log`

## Seed local demo data

Run:

```powershell
D:\PycharmProjects\androidapp\backend_fastapi\venv\Scripts\python.exe D:\PycharmProjects\androidapp\backend_fastapi\seed_local_demo_data.py --host 127.0.0.1 --scheme http
```

This guarantees:

- one client account
- two company accounts
- company profiles filled with categories
- one fresh open request visible to both companies

Default accounts:

- Client: `local_client@example.com` / `Test1234!`
- Company 1: `local_company_main@example.com` / `Test1234!`
- Company 2: `local_company_alt@example.com` / `Test1234!`

## Swagger and health checks

- Auth docs: [http://127.0.0.1:8001/docs](http://127.0.0.1:8001/docs)
- Client docs: [http://127.0.0.1:8002/docs](http://127.0.0.1:8002/docs)
- Company docs: [http://127.0.0.1:8003/docs](http://127.0.0.1:8003/docs)
- Category docs: [http://127.0.0.1:8004/docs](http://127.0.0.1:8004/docs)
- Ordering docs: [http://127.0.0.1:8005/docs](http://127.0.0.1:8005/docs)
- Chat docs: [http://127.0.0.1:8006/docs](http://127.0.0.1:8006/docs)
- Review docs: [http://127.0.0.1:8007/docs](http://127.0.0.1:8007/docs)
- File docs: [http://127.0.0.1:8008/docs](http://127.0.0.1:8008/docs)

Quick health check:

```powershell
D:\PycharmProjects\androidapp\backend_fastapi\venv\Scripts\python.exe D:\PycharmProjects\androidapp\backend_fastapi\check_services.py
```

## Manual QA flow

1. Open `http://127.0.0.1:3000`.
2. Login as `local_client@example.com`.
3. Open the client requests screen and verify the fresh seeded request is present.
4. Logout and login as `local_company_main@example.com`.
5. Open company inquiries and verify the same request is visible.
6. Create a response with price, deadline, specialist, and enrollment date.
7. Logout and login as `local_client@example.com`.
8. Open the request details and verify the company response appears.
9. Open the company card from the response and confirm the enrollment date.
10. Logout and login as `local_company_main@example.com`.
11. Open company orders and verify the order is confirmed/enrolled.
12. Finish the order.
13. Logout and login as `local_client@example.com`.
14. Verify the order is finished and the review action is available.
15. Submit a review.

Optional negative checks:

1. Login as `local_company_alt@example.com`.
2. Verify the request is visible before the client confirms another company.
3. After the client confirms Company 1, verify Company 2 does not become the active order owner for that confirmed order.

## Automated checks

Backend targeted tests:

```powershell
cd D:\PycharmProjects\androidapp
python -m pytest backend_fastapi/tests/test_client_service.py backend_fastapi/tests/test_ordering_service.py backend_fastapi/tests/test_order_state_machine.py backend_fastapi/tests/test_permission_guards.py -q
```

Backend smoke lifecycle:

```powershell
cd D:\PycharmProjects\androidapp\backend_fastapi
venv\Scripts\python.exe smoke_test_backend.py --host 127.0.0.1 --scheme http --client-email local_client@example.com --client-password Test1234! --company-email local_company_main@example.com --company-password Test1234!
```

Flutter tests:

```powershell
cd D:\PycharmProjects\androidapp\client_app_flutter
flutter test
```

Focused Flutter analyze:

```powershell
cd D:\PycharmProjects\androidapp\client_app_flutter
flutter analyze lib/screens/client_view_inquiry_screen.dart lib/screens/company_detail_screen.dart lib/screens/company_client_detail_screen.dart lib/services/remote_ordering_service.dart
```

## Reset notes

- Re-running `seed_local_demo_data.py` is safe. It reuses the same accounts and creates a new fresh request.
- If you want a clean DB, remove `D:\PycharmProjects\androidapp\backend_fastapi\choice.db` only when all backend services are stopped.
