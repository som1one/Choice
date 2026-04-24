#!/usr/bin/env python3
"""Smoke test for Choice backend inquiry flow.

Checks the core path:
1. login company
2. determine a valid category from company profile
3. login or register client
4. create order request
5. verify client sees the request
6. verify company sees the request
"""

from __future__ import annotations

import argparse
import json
import random
import string
import sys
import time
from dataclasses import dataclass
from datetime import datetime
from typing import Any
from urllib import error, parse, request


@dataclass
class Config:
    scheme: str
    host: str
    auth_port: int = 8001
    client_port: int = 8002
    company_port: int = 8003

    def url(self, service: str, path: str) -> str:
        port = {
            "auth": self.auth_port,
            "client": self.client_port,
            "company": self.company_port,
        }[service]
        return f"{self.scheme}://{self.host}:{port}{path}"


def _json_request(
    method: str,
    url: str,
    body: dict[str, Any] | None = None,
    token: str | None = None,
) -> tuple[int, Any]:
    data = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if body is not None:
        data = json.dumps(body).encode("utf-8")

    req = request.Request(url, data=data, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=20) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else None
    except error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        return exc.code, parsed


def _print_step(title: str) -> None:
    print(f"\n== {title} ==")


def _expect(status: int, expected: int, payload: Any, context: str) -> None:
    if status != expected:
        raise RuntimeError(
            f"{context} failed: expected {expected}, got {status}, payload={payload}"
        )


def login(config: Config, email: str, password: str) -> str:
    status, payload = _json_request(
        "POST",
        config.url("auth", "/api/auth/login"),
        {"email": email, "password": password},
    )
    _expect(status, 200, payload, f"login for {email}")
    token = (payload or {}).get("access_token")
    if not token:
        raise RuntimeError(f"login for {email} returned no token: {payload}")
    return token


def register_client(
    config: Config,
    password: str,
    city: str,
    street: str,
) -> tuple[str, str]:
    suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=8))
    email = f"smoke_client_{suffix}@example.com"
    phone = f"79{random.randint(100000000, 999999999)}"
    payload = {
        "email": email,
        "name": f"Smoke Client {suffix}",
        "password": password,
        "street": street,
        "city": city,
        "phone_number": phone,
        "type": "Client",
    }
    status, response_payload = _json_request(
        "POST",
        config.url("auth", "/api/auth/register"),
        payload,
    )
    _expect(status, 200, response_payload, "client registration")
    token = (response_payload or {}).get("access_token")
    if not token:
        raise RuntimeError(f"registration returned no token: {response_payload}")
    return email, token


def get_company_profile(config: Config, token: str) -> dict[str, Any]:
    status, payload = _json_request(
        "GET",
        config.url("company", "/api/company/get"),
        token=token,
    )
    _expect(status, 200, payload, "get company profile")
    if not isinstance(payload, dict):
        raise RuntimeError(f"company profile has unexpected shape: {payload}")
    return payload


def get_client_profile(config: Config, token: str) -> dict[str, Any]:
    status, payload = _json_request(
        "GET",
        config.url("client", "/api/client/get"),
        token=token,
    )
    _expect(status, 200, payload, "get client profile")
    if not isinstance(payload, dict):
        raise RuntimeError(f"client profile has unexpected shape: {payload}")
    return payload


def create_order_request(
    config: Config,
    token: str,
    category_id: int,
    description: str,
    radius: int,
) -> dict[str, Any]:
    payload = {
        "category_id": category_id,
        "description": description,
        "search_radius": radius,
        "to_know_price": True,
        "to_know_deadline": True,
        "to_know_specialist": True,
        "to_know_enrollment_date": True,
        "photo_uris": [],
    }
    status, response_payload = _json_request(
        "POST",
        config.url("client", "/api/client/sendOrderRequest"),
        payload,
        token=token,
    )
    _expect(status, 200, response_payload, "create order request")
    if not isinstance(response_payload, dict):
        raise RuntimeError(f"create order request returned unexpected shape: {response_payload}")
    return response_payload


def get_client_requests(config: Config, token: str) -> list[dict[str, Any]]:
    status, payload = _json_request(
        "GET",
        config.url("client", "/api/client/getClientRequests"),
        token=token,
    )
    _expect(status, 200, payload, "get client requests")
    if not isinstance(payload, list):
        raise RuntimeError(f"client requests returned unexpected shape: {payload}")
    return payload


def get_company_requests(config: Config, token: str) -> list[dict[str, Any]]:
    status, payload = _json_request(
        "GET",
        config.url("company", "/api/company/getOrderRequests"),
        token=token,
    )
    _expect(status, 200, payload, "get company requests")
    if not isinstance(payload, list):
        raise RuntimeError(f"company requests returned unexpected shape: {payload}")
    return payload


def wait_for_request(
    loader,
    request_id: int,
    attempts: int = 5,
    delay_seconds: float = 1.5,
) -> list[dict[str, Any]]:
    latest: list[dict[str, Any]] = []
    for _ in range(attempts):
        latest = loader()
        for item in latest:
            item_id = item.get("id") or item.get("order_request_id")
            try:
                if int(item_id) == request_id:
                    return latest
            except Exception:
                continue
        time.sleep(delay_seconds)
    return latest


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Smoke test Choice backend")
    parser.add_argument("--host", default="77.95.203.148")
    parser.add_argument("--scheme", default="http")
    parser.add_argument("--client-email")
    parser.add_argument("--client-password", default="Test1234!")
    parser.add_argument("--company-email", required=True)
    parser.add_argument("--company-password", required=True)
    parser.add_argument("--register-client", action="store_true")
    parser.add_argument("--city", default="Москва")
    parser.add_argument("--street", default="Ленина 1")
    parser.add_argument("--radius", type=int, default=20000)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = Config(scheme=args.scheme, host=args.host)

    _print_step("Company Login")
    company_token = login(config, args.company_email, args.company_password)
    company_profile = get_company_profile(config, company_token)
    company_categories = company_profile.get("categories_id") or company_profile.get("categoriesId") or []
    if not isinstance(company_categories, list) or not company_categories:
      raise RuntimeError(
          f"company has no categories configured: {company_profile}"
      )
    category_id = int(company_categories[0])
    print(f"company={company_profile.get('title')} category_id={category_id}")

    _print_step("Client Login/Register")
    if args.register_client:
        client_email, client_token = register_client(
            config=config,
            password=args.client_password,
            city=args.city,
            street=args.street,
        )
        print(f"registered client={client_email}")
    else:
        if not args.client_email:
            raise RuntimeError("--client-email is required unless --register-client is used")
        client_email = args.client_email
        client_token = login(config, args.client_email, args.client_password)
        print(f"logged in client={client_email}")

    client_profile = get_client_profile(config, client_token)
    print(
        "client_profile="
        f"{client_profile.get('name')} {client_profile.get('surname')} "
        f"city={client_profile.get('city')} street={client_profile.get('street')}"
    )

    _print_step("Create Request")
    marker = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    description = f"Smoke test request {marker}"
    created = create_order_request(
        config=config,
        token=client_token,
        category_id=category_id,
        description=description,
        radius=args.radius,
    )
    request_id = int(created["id"])
    print(f"created request_id={request_id}")

    _print_step("Verify Client Requests")
    client_requests = wait_for_request(
        lambda: get_client_requests(config, client_token),
        request_id=request_id,
    )
    if not any(int(item.get("id", -1)) == request_id for item in client_requests):
        raise RuntimeError(
            f"client does not see request_id={request_id}. payload={client_requests}"
        )
    print(f"client sees request_id={request_id}")

    _print_step("Verify Company Requests")
    company_requests = wait_for_request(
        lambda: get_company_requests(config, company_token),
        request_id=request_id,
    )
    found = False
    for item in company_requests:
        try:
            if int(item.get("id", -1)) == request_id:
                found = True
                break
        except Exception:
            continue
    if not found:
        raise RuntimeError(
            "company does not see request "
            f"request_id={request_id}. payload={company_requests}"
        )
    print(f"company sees request_id={request_id}")

    print("\nSUCCESS: backend inquiry flow is healthy")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"\nFAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
