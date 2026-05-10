#!/usr/bin/env python3
"""Seed stable local data for manual Choice testing."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

from create_test_accounts import (
    Config as AccountConfig,
    fill_company_data,
    get_categories,
    login_user,
    register_user,
)
from smoke_test_backend import (
    Config as FlowConfig,
    create_order_request,
    get_client_profile,
    get_company_profile,
)


DEFAULT_PASSWORD = "Test1234!"
DEFAULT_CITY = "Omsk"
DEFAULT_STREET = "Lenina, 1"


@dataclass
class AccountSpec:
    email: str
    name: str
    user_type: str


CLIENT = AccountSpec(
    email="local_client@example.com",
    name="Local Client",
    user_type="Client",
)

COMPANIES = [
    AccountSpec(
        email="local_company_main@example.com",
        name="Local Company Main",
        user_type="Company",
    ),
    AccountSpec(
        email="local_company_alt@example.com",
        name="Local Company Alt",
        user_type="Company",
    ),
]


def ensure_user_token(
    config: AccountConfig,
    *,
    spec: AccountSpec,
    password: str,
    city: str,
    street: str,
) -> tuple[str, bool]:
    try:
        return login_user(config, email=spec.email, password=password), True
    except Exception:
        token = register_user(
            config,
            email=spec.email,
            name=spec.name,
            password=password,
            city=city,
            street=street,
            phone_number="79000000000",
            user_type=spec.user_type,
        )
        return token, False


def ensure_company_profile(
    account_config: AccountConfig,
    flow_config: FlowConfig,
    *,
    spec: AccountSpec,
    token: str,
    company_categories: int,
) -> dict[str, Any]:
    categories = get_categories(account_config)
    selected_ids = [
        int(item["id"])
        for item in categories[: max(company_categories, 0)]
        if isinstance(item, dict) and "id" in item
    ]
    if not selected_ids:
        raise RuntimeError("No categories available to fill company data")

    fill_company_data(
        account_config,
        token=token,
        title=spec.name,
        category_ids=selected_ids,
        site_url=f"https://{spec.email.split('@', 1)[0]}.local",
        description="Local seeded company profile for manual QA.",
        card_color="#2196F3",
    )
    profile = get_company_profile(flow_config, token)
    profile["seeded_categories"] = selected_ids
    return profile


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Seed stable local demo data")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--scheme", default="http")
    parser.add_argument("--password", default=DEFAULT_PASSWORD)
    parser.add_argument("--city", default=DEFAULT_CITY)
    parser.add_argument("--street", default=DEFAULT_STREET)
    parser.add_argument("--company-categories", type=int, default=3)
    parser.add_argument("--radius", type=int, default=20000)
    parser.add_argument("--skip-request", action="store_true")
    parser.add_argument("--json", action="store_true")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    account_config = AccountConfig(scheme=args.scheme, host=args.host)
    flow_config = FlowConfig(scheme=args.scheme, host=args.host)

    client_token, client_reused = ensure_user_token(
        account_config,
        spec=CLIENT,
        password=args.password,
        city=args.city,
        street=args.street,
    )
    client_profile = get_client_profile(flow_config, client_token)

    companies_result: list[dict[str, Any]] = []
    main_company_profile: dict[str, Any] | None = None
    for index, spec in enumerate(COMPANIES):
        company_token, company_reused = ensure_user_token(
            account_config,
            spec=spec,
            password=args.password,
            city=args.city,
            street=args.street,
        )
        company_profile = ensure_company_profile(
            account_config,
            flow_config,
            spec=spec,
            token=company_token,
            company_categories=args.company_categories,
        )
        if index == 0:
            main_company_profile = company_profile
        companies_result.append(
            {
                "email": spec.email,
                "name": spec.name,
                "password": args.password,
                "reused": company_reused,
                "guid": company_profile.get("guid"),
                "categories_id": company_profile.get("seeded_categories"),
                "token": company_token,
            }
        )

    if main_company_profile is None:
        raise RuntimeError("Main company profile was not created")

    request_result: dict[str, Any] | None = None
    if not args.skip_request:
        categories = main_company_profile.get("categories_id") or main_company_profile.get("categoriesId") or []
        if not categories:
            raise RuntimeError("Main company has no categories configured")
        category_id = int(categories[0])
        marker = datetime.now(UTC).strftime("%Y-%m-%d %H:%M:%S")
        description = f"Manual QA request {marker}"
        created_request = create_order_request(
            flow_config,
            client_token,
            category_id=category_id,
            description=description,
            radius=args.radius,
        )
        request_result = {
            "id": created_request.get("id"),
            "category_id": category_id,
            "description": description,
        }

    result = {
        "host": args.host,
        "scheme": args.scheme,
        "database": "backend_fastapi/choice.db",
        "client": {
            "email": CLIENT.email,
            "name": CLIENT.name,
            "password": args.password,
            "reused": client_reused,
            "guid": client_profile.get("guid"),
            "token": client_token,
        },
        "companies": companies_result,
        "request": request_result,
    }

    if args.json:
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        print("Seeded local demo data:")
        print(f"- client: {CLIENT.email} / {args.password}")
        for company in companies_result:
            state = "reused" if company["reused"] else "created"
            print(f"- company ({state}): {company['email']} / {company['password']}")
        if request_result:
            print(f"- fresh request id: {request_result['id']}")
            print(f"  description: {request_result['description']}")
        print("")
        print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("\nInterrupted", file=sys.stderr)
        raise SystemExit(130)
