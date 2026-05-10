"""Shared test factories for backend service scenarios."""

from __future__ import annotations

import uuid
from datetime import datetime

from common.security import create_access_token
from services.authentication.models import User, UserType
from services.client_service.models import Client, OrderRequest
from services.company_service.models import Company
from services.ordering.models import Order, OrderStatus

DEFAULT_COORDINATES = "55.7558,37.6173"


def build_token(user: User) -> str:
    """Create an access token that matches the app's current auth expectations."""
    return create_access_token(
        data={
            "id": str(user.id),
            "email": user.email,
            "user_type": user.user_type.value,
            "address": None,
        }
    )


def create_user(
    db,
    *,
    email: str,
    user_type: UserType,
    user_name: str,
    phone_number: str | None = None,
    city: str | None = None,
    street: str | None = None,
) -> User:
    user = User(
        id=uuid.uuid4(),
        email=email,
        password_hash="hash",
        user_type=user_type,
        user_name=user_name,
        phone_number=phone_number,
        city=city,
        street=street,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def create_client_profile(
    db,
    user: User,
    *,
    name: str = "Client",
    surname: str = "User",
    phone_number: str = "+1234567890",
    city: str = "Moscow",
    street: str = "Test Street",
    coordinates: str = DEFAULT_COORDINATES,
    icon_uri: str | None = None,
) -> Client:
    client = Client(
        guid=str(user.id),
        name=name,
        surname=surname,
        email=user.email,
        phone_number=phone_number,
        city=city,
        street=street,
        coordinates=coordinates,
        icon_uri=icon_uri,
    )
    db.add(client)
    db.commit()
    db.refresh(client)
    return client


def create_company_profile(
    db,
    user: User,
    *,
    title: str = "Test Company",
    phone_number: str = "+79876543210",
    city: str = "Moscow",
    street: str = "Test Street",
    coordinates: str = DEFAULT_COORDINATES,
    categories_id: list[int] | None = None,
    description: str = "Company description",
    prepayment_available: bool = True,
) -> Company:
    company = Company(
        guid=str(user.id),
        title=title,
        phone_number=phone_number,
        email=user.email,
        city=city,
        street=street,
        coordinates=coordinates,
        categories_id=categories_id or [1],
        description=description,
        prepayment_available=prepayment_available,
        is_data_filled=True,
    )
    db.add(company)
    db.commit()
    db.refresh(company)
    return company


def create_order_request(
    db,
    client: Client,
    *,
    category_id: int = 1,
    description: str = "Need service",
    search_radius: int = 20000,
    to_know_price: str = "true",
    to_know_deadline: str = "true",
    to_know_specialist: str = "true",
    to_know_enrollment_date: str = "true",
    photo_uris: str | None = None,
    status: int = 0,
    creation_date: datetime | None = None,
) -> OrderRequest:
    order_request = OrderRequest(
        client_id=client.id,
        category_id=category_id,
        description=description,
        search_radius=search_radius,
        to_know_price=to_know_price,
        to_know_deadline=to_know_deadline,
        to_know_specialist=to_know_specialist,
        to_know_enrollment_date=to_know_enrollment_date,
        photo_uris=photo_uris,
        status=status,
        creation_date=creation_date or datetime.utcnow(),
    )
    db.add(order_request)
    db.commit()
    db.refresh(order_request)
    return order_request


def create_order(
    db,
    *,
    order_request_id: int,
    company_id: str,
    client_id: str,
    price: int = 1000,
    prepayment: int = 0,
    deadline: int = 7,
    status: int = OrderStatus.ACTIVE.value,
    is_enrolled: bool = False,
    is_date_confirmed: bool = False,
    enrollment_date: datetime | None = None,
    response_text: str | None = None,
    specialist_name: str | None = None,
    specialist_phone: str | None = None,
    reviews: list[str] | None = None,
) -> Order:
    order = Order(
        order_request_id=order_request_id,
        company_id=company_id,
        client_id=client_id,
        price=price,
        prepayment=prepayment,
        deadline=deadline,
        status=status,
        is_enrolled=is_enrolled,
        is_date_confirmed=is_date_confirmed,
        enrollment_date=enrollment_date,
        response_text=response_text,
        specialist_name=specialist_name,
        specialist_phone=specialist_phone,
        reviews=reviews or [],
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order
