import asyncio
from datetime import datetime, timedelta
from pathlib import Path
import sys

import pytest
from fastapi import HTTPException
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

BACKEND_ROOT = Path(__file__).resolve().parents[1]
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

from common.database import Base
from services.client_service.models import Client, OrderRequest
from services.client_service.routers.client import change_order_request
from services.client_service.schemas import ChangeOrderRequestRequest
from services.ordering.models import Order, OrderStatus
from services.ordering.routers.order import (
    cancel_enrollment,
    change_enrollment_date,
    confirm_enrollment_date,
    enroll,
    finish_order,
)
from services.ordering.schemas import ChangeEnrollmentDateRequest


ORDERING_TABLES = [Order.__table__, Client.__table__, OrderRequest.__table__]


@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite:///:memory:",
        connect_args={"check_same_thread": False},
    )
    SessionLocal = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    Base.metadata.create_all(engine, tables=ORDERING_TABLES)
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(engine, tables=ORDERING_TABLES)
        engine.dispose()


def _create_order(db, **overrides) -> Order:
    order = Order(
        order_request_id=overrides.get("order_request_id", 1),
        company_id=overrides.get("company_id", "company-1"),
        client_id=overrides.get("client_id", "client-1"),
        price=overrides.get("price", 1000),
        prepayment=overrides.get("prepayment", 0),
        deadline=overrides.get("deadline", 1),
        response_text=overrides.get("response_text"),
        specialist_name=overrides.get("specialist_name"),
        specialist_phone=overrides.get("specialist_phone"),
        enrollment_date=overrides.get("enrollment_date", datetime.utcnow()),
        is_enrolled=overrides.get("is_enrolled", False),
        is_date_confirmed=overrides.get("is_date_confirmed", False),
        reviews=overrides.get("reviews", []),
        status=overrides.get("status", OrderStatus.ACTIVE.value),
        user_changed_enrollment_date_guid=overrides.get(
            "user_changed_enrollment_date_guid"
        ),
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order


def _create_client(db, guid: str) -> Client:
    client = Client(
        guid=guid,
        name="Test",
        surname="User",
        email=f"{guid}@example.com",
        phone_number="123",
        city="City",
        street="Street",
        coordinates="0,0",
    )
    db.add(client)
    db.commit()
    db.refresh(client)
    return client


def _create_request(db, client_id: int) -> OrderRequest:
    request = OrderRequest(
        client_id=client_id,
        category_id=10,
        description="original",
        search_radius=5,
        to_know_price="true",
        to_know_deadline="false",
        to_know_specialist="false",
        to_know_enrollment_date="false",
        status=0,
        creation_date=datetime.utcnow(),
    )
    db.add(request)
    db.commit()
    db.refresh(request)
    return request


def test_finish_order_still_allows_participants(db_session):
    client_order = _create_order(
        db_session,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    result = asyncio.run(
        finish_order(
            client_order.id,
            db=db_session,
            current_user={"id": "client-1", "user_type": "Client"},
        )
    )
    assert result.status == OrderStatus.FINISHED.value

    company_order = _create_order(
        db_session,
        order_request_id=2,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    result = asyncio.run(
        finish_order(
            company_order.id,
            db=db_session,
            current_user={"id": "company-1", "user_type": "Company"},
        )
    )
    assert result.status == OrderStatus.FINISHED.value


def test_enroll_requires_client_owner(db_session):
    allowed_order = _create_order(db_session)
    result = asyncio.run(
        enroll(
            allowed_order.id,
            db=db_session,
            current_user={"id": "client-1", "user_type": "Client"},
        )
    )
    assert result.is_enrolled is True
    assert result.is_date_confirmed is True

    blocked_order = _create_order(db_session, order_request_id=2)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            enroll(
                blocked_order.id,
                db=db_session,
                current_user={"id": "company-1", "user_type": "Company"},
            )
        )
    assert exc_info.value.status_code == 403


def test_confirm_enrollment_requires_client_owner(db_session):
    allowed_order = _create_order(db_session)
    result = asyncio.run(
        confirm_enrollment_date(
            allowed_order.id,
            db=db_session,
            current_user={"id": "client-1", "user_type": "Client"},
        )
    )
    assert result.is_enrolled is True
    assert result.is_date_confirmed is True

    blocked_order = _create_order(db_session, order_request_id=2)
    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            confirm_enrollment_date(
                blocked_order.id,
                db=db_session,
                current_user={"id": "company-1", "user_type": "Company"},
            )
        )
    assert exc_info.value.status_code == 403


def test_change_and_cancel_enrollment_require_participant(db_session):
    changeable_order = _create_order(
        db_session,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    new_date = datetime.utcnow() + timedelta(days=3)
    changed = asyncio.run(
        change_enrollment_date(
            ChangeEnrollmentDateRequest(
                order_id=changeable_order.id,
                enrollment_date=new_date,
            ),
            db=db_session,
            current_user={"id": "company-1", "user_type": "Company"},
        )
    )
    assert changed.enrollment_date == new_date
    assert changed.is_enrolled is False
    assert changed.is_date_confirmed is False

    blocked_change_order = _create_order(
        db_session,
        order_request_id=2,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            change_enrollment_date(
                ChangeEnrollmentDateRequest(
                    order_id=blocked_change_order.id,
                    enrollment_date=new_date,
                ),
                db=db_session,
                current_user={"id": "outsider", "user_type": "Client"},
            )
        )
    assert exc_info.value.status_code == 403

    cancelable_order = _create_order(
        db_session,
        order_request_id=3,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    canceled = asyncio.run(
        cancel_enrollment(
            cancelable_order.id,
            db=db_session,
            current_user={"id": "company-1", "user_type": "Company"},
        )
    )
    assert canceled.is_enrolled is False
    assert canceled.is_date_confirmed is False
    assert canceled.enrollment_date is None

    blocked_cancel_order = _create_order(
        db_session,
        order_request_id=4,
        is_enrolled=True,
        is_date_confirmed=True,
    )
    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            cancel_enrollment(
                blocked_cancel_order.id,
                db=db_session,
                current_user={"id": "outsider", "user_type": "Client"},
            )
        )
    assert exc_info.value.status_code == 403


def test_change_order_request_requires_owner(db_session):
    owner = _create_client(db_session, "owner-guid")
    _create_client(db_session, "other-guid")
    request = _create_request(db_session, owner.id)

    updated = asyncio.run(
        change_order_request(
            ChangeOrderRequestRequest(
                id=request.id,
                category_id=99,
                description="updated by owner",
                search_radius=50,
                to_know_price=False,
                to_know_deadline=True,
                to_know_specialist=True,
                to_know_enrollment_date=False,
                photo_uris=[],
            ),
            db=db_session,
            current_user={"id": "owner-guid", "user_type": "Client"},
        )
    )
    assert updated.category_id == 99
    assert updated.description == "updated by owner"

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            change_order_request(
                ChangeOrderRequestRequest(
                    id=request.id,
                    category_id=77,
                    description="updated by outsider",
                    search_radius=70,
                    to_know_price=True,
                    to_know_deadline=False,
                    to_know_specialist=False,
                    to_know_enrollment_date=True,
                    photo_uris=[],
                ),
                db=db_session,
                current_user={"id": "other-guid", "user_type": "Client"},
            )
        )
    assert exc_info.value.status_code == 403
