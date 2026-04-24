#!/usr/bin/env python3
"""Create disposable Choice test accounts through the public API.

By default creates:
- one client
- one company

The company can also be auto-filled with categories so it is immediately
usable in the inquiry flow.
"""

from __future__ import annotations

import argparse
import json
import random
import string
import sys
from dataclasses import dataclass
from typing import Any
from urllib import error, request


@dataclass
class Config:
    scheme: str
    host: str
    auth_port: int = 8001
    company_port: int = 8003
    category_port: int = 8004

    def url(self, service: str, path: str) -> str:
        port = {
            "auth": self.auth_port,
            "company": self.company_port,
            "category": self.category_port,
        }[service]
        return f"{self.scheme}://{self.host}:{port}{path}"


def _json_request(
    method: str,
    url: str,
    body: dict[str, Any] | None = None,
    token: str | None = None,
) -> tuple[int, Any]:
    payload = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if body is not None:
        payload = json.dumps(body).encode("utf-8")

    req = request.Request(url, data=payload, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=30) as response:
            raw = response.read().decode("utf-8")
            return response.status, json.loads(raw) if raw else None
    except error.HTTPError as exc:
        raw = exc.read().decode("utf-8", errors="ignore")
        try:
            parsed = json.loads(raw) if raw else None
        except Exception:
            parsed = raw
        return exc.code, parsed


def _expect_ok(status: int, payload: Any, context: str) -> None:
    if status == 200:
        return
    raise RuntimeError(f"{context} failed: status={status}, payload={payload}")


def _random_suffix(length: int = 8) -> str:
    alphabet = string.ascii_lowercase + string.digits
    return "".join(random.choices(alphabet, k=length))


def _make_phone() -> str:
    return f"79{random.randint(100000000, 999999999)}"


def register_user(
    config: Config,
    *,
    email: str,
    name: str,
    password: str,
    city: str,
    street: str,
    phone_number: str,
    user_type: str,
) -> str:
    status, payload = _json_request(
        "POST",
        config.url("auth", "/api/auth/register"),
        {
            "email": email,
            "name": name,
            "password": password,
            "street": street,
            "city": city,
            "phone_number": phone_number,
            "type": user_type,
        },
    )
    _expect_ok(status, payload, f"register {user_type} {email}")
    token = (payload or {}).get("access_token")
    if not token:
        raise RuntimeError(f"register {email} returned no token: {payload}")
    return token


def login_user(config: Config, *, email: str, password: str) -> str:
    status, payload = _json_request(
        "POST",
        config.url("auth", "/api/auth/login"),
        {"email": email, "password": password},
    )
    _expect_ok(status, payload, f"login {email}")
    token = (payload or {}).get("access_token")
    if not token:
        raise RuntimeError(f"login {email} returned no token: {payload}")
    return token


def get_categories(config: Config) -> list[dict[str, Any]]:
    status, payload = _json_request(
        "GET",
        config.url("category", "/api/category/get"),
    )
    _expect_ok(status, payload, "get categories")
    if not isinstance(payload, list):
        raise RuntimeError(f"categories returned unexpected payload: {payload}")
    return [item for item in payload if isinstance(item, dict)]


def fill_company_data(
    config: Config,
    *,
    token: str,
    title: str,
    category_ids: list[int],
    site_url: str,
    description: str,
    card_color: str,
) -> dict[str, Any]:
    status, payload = _json_request(
        "PUT",
        config.url("company", "/api/company/fillCompanyData"),
        {
            "site_url": site_url,
            "social_medias": [],
            "photo_uris": [],
            "categories_id": category_ids,
            "prepayment_available": False,
            "description": description,
            "card_color": card_color,
        },
        token=token,
    )
    _expect_ok(status, payload, f"fill company data for {title}")
    if not isinstance(payload, dict):
        raise RuntimeError(f"fillCompanyData returned unexpected payload: {payload}")
    return payload


def maybe_reuse_account(
    config: Config,
    *,
    email: str,
    password: str,
    enabled: bool,
) -> str | None:
    if not enabled:
        return None
    try:
        return login_user(config, email=email, password=password)
    except Exception:
        return None


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Create Choice test client/company accounts via API.",
    )
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--scheme", default="http")
    parser.add_argument("--password", default="Test1234!")
    parser.add_argument("--city", default="Омск")
    parser.add_argument("--street", default="Ленина, 1")
    parser.add_argument("--suffix", default=_random_suffix())
    parser.add_argument("--company-email")
    parser.add_argument("--client-email")
    parser.add_argument("--company-name")
    parser.add_argument("--client-name")
    parser.add_argument("--company-categories", type=int, default=3)
    parser.add_argument("--skip-client", action="store_true")
    parser.add_argument("--skip-company", action="store_true")
    parser.add_argument("--skip-company-fill", action="store_true")
    parser.add_argument("--login-if-exists", action="store_true")
    parser.add_argument("--json", action="store_true", help="Print JSON only.")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    config = Config(scheme=args.scheme, host=args.host)
    suffix = args.suffix

    results: dict[str, Any] = {
        "host": args.host,
        "scheme": args.scheme,
        "password": args.password,
    }

    if not args.skip_client:
        client_email = args.client_email or f"test_client_{suffix}@example.com"
        client_name = args.client_name or f"Test Client {suffix}"
        client_phone = _make_phone()

        client_token = maybe_reuse_account(
            config,
            email=client_email,
            password=args.password,
            enabled=args.login_if_exists,
        )
        reused_client = client_token is not None
        if client_token is None:
            client_token = register_user(
                config,
                email=client_email,
                name=client_name,
                password=args.password,
                city=args.city,
                street=args.street,
                phone_number=client_phone,
                user_type="Client",
            )

        results["client"] = {
            "email": client_email,
            "name": client_name,
            "password": args.password,
            "city": args.city,
            "street": args.street,
            "token": client_token,
            "reused": reused_client,
        }

    if not args.skip_company:
        company_email = args.company_email or f"test_company_{suffix}@example.com"
        company_name = args.company_name or f"Test Company {suffix}"
        company_phone = _make_phone()

        company_token = maybe_reuse_account(
            config,
            email=company_email,
            password=args.password,
            enabled=args.login_if_exists,
        )
        reused_company = company_token is not None
        if company_token is None:
            company_token = register_user(
                config,
                email=company_email,
                name=company_name,
                password=args.password,
                city=args.city,
                street=args.street,
                phone_number=company_phone,
                user_type="Company",
            )

        company_result: dict[str, Any] = {
            "email": company_email,
            "name": company_name,
            "password": args.password,
            "city": args.city,
            "street": args.street,
            "token": company_token,
            "reused": reused_company,
        }

        if not args.skip_company_fill:
            categories = get_categories(config)
            selected_ids = [
                int(item["id"])
                for item in categories[: max(args.company_categories, 0)]
                if "id" in item
            ]
            if not selected_ids:
                raise RuntimeError("No categories available to fill company data")
            company_profile = fill_company_data(
                config,
                token=company_token,
                title=company_name,
                category_ids=selected_ids,
                site_url=f"https://{company_email.split('@', 1)[0]}.test",
                description="Автоматически созданный тестовый аккаунт компании",
                card_color="#2196F3",
            )
            company_result["filled"] = True
            company_result["categories_id"] = selected_ids
            company_result["profile"] = {
                "guid": company_profile.get("guid"),
                "title": company_profile.get("title"),
                "coords": company_profile.get("coords"),
            }
        else:
            company_result["filled"] = False

        results["company"] = company_result

    if args.json:
        print(json.dumps(results, ensure_ascii=False, indent=2))
        return 0

    print("Created test accounts:")
    if "client" in results:
        client = results["client"]
        state = "reused" if client["reused"] else "created"
        print(f"- client  ({state}): {client['email']} / {client['password']}")
    if "company" in results:
        company = results["company"]
        state = "reused" if company["reused"] else "created"
        print(f"- company ({state}): {company['email']} / {company['password']}")
        if company.get("filled"):
            print(f"  categories: {company['categories_id']}")
    print("\nJSON:")
    print(json.dumps(results, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        raise SystemExit(130)
