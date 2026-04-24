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
from services.ordering.models import Order, OrderStatus
from services.ordering.routers.order import (
    cancel_enrollment,
    change_enrollment_date,
    confirm_enrollment_date,
    create_order,
    enroll,
)
from services.ordering.schemas import ChangeEnrollmentDateRequest, CreateOrderRequest


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


def _create_client(db, guid: str, *, email: str | None = None) -> Client:
    client = Client(
        guid=guid,
        name="Client",
        surname="User",
        email=email or f"{guid}@example.com",
        phone_number="123",
        city="City",
        street="Street",
        coordinates="0,0",
    )
    db.add(client)
    db.commit()
    db.refresh(client)
    return client


def _create_request(
    db,
    *,
    client_id: int,
    status: int = 0,
    category_id: int = 10,
    description: str = "request",
) -> OrderRequest:
    request = OrderRequest(
        client_id=client_id,
        category_id=category_id,
        description=description,
        search_radius=10,
        to_know_price="true",
        to_know_deadline="false",
        to_know_specialist="false",
        to_know_enrollment_date="true",
        photo_uris=None,
        status=status,
        creation_date=datetime.utcnow(),
    )
    db.add(request)
    db.commit()
    db.refresh(request)
    return request


def _create_order(
    db,
    *,
    order_request_id: int,
    company_id: str,
    client_id: str,
    status: int = OrderStatus.ACTIVE.value,
    enrollment_date: datetime | None = None,
    is_enrolled: bool = False,
    is_date_confirmed: bool = False,
) -> Order:
    order = Order(
        order_request_id=order_request_id,
        company_id=company_id,
        client_id=client_id,
        price=1000,
        prepayment=0,
        deadline=1,
        response_text="response",
        specialist_name=None,
        specialist_phone=None,
        enrollment_date=enrollment_date,
        is_enrolled=is_enrolled,
        is_date_confirmed=is_date_confirmed,
        reviews=[],
        status=status,
    )
    db.add(order)
    db.commit()
    db.refresh(order)
    return order


def test_cancel_enrollment_sets_canceled_status_and_clears_fields(db_session):
    client = _create_client(db_session, "client-1")
    request = _create_request(db_session, client_id=client.id)
    order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-1",
        client_id=client.guid,
        status=OrderStatus.ACTIVE.value,
        enrollment_date=datetime.utcnow(),
        is_enrolled=True,
        is_date_confirmed=True,
    )

    canceled = asyncio.run(
        cancel_enrollment(
            order.id,
            db=db_session,
            current_user={"id": "company-1", "user_type": "Company"},
        )
    )
    assert canceled.status == OrderStatus.CANCELED.value
    assert canceled.is_enrolled is False
    assert canceled.is_date_confirmed is False
    assert canceled.enrollment_date is None

    # Идемпотентность повторной отмены
    canceled_again = asyncio.run(
        cancel_enrollment(
            order.id,
            db=db_session,
            current_user={"id": "company-1", "user_type": "Company"},
        )
    )
    assert canceled_again.status == OrderStatus.CANCELED.value


def test_create_order_reactivates_canceled_order(db_session):
    client = _create_client(db_session, "client-reactivate")
    request = _create_request(db_session, client_id=client.id, status=0)
    order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-reactivate",
        client_id=client.guid,
        status=OrderStatus.CANCELED.value,
        enrollment_date=None,
        is_enrolled=False,
        is_date_confirmed=False,
    )

    result = asyncio.run(
        create_order(
            CreateOrderRequest(
                receiver_id=client.guid,
                order_request_id=request.id,
                price=2500,
                deadline=3,
                enrollment_date=datetime.utcnow() + timedelta(days=1),
            ),
            db=db_session,
            current_user={"id": "company-reactivate", "user_type": "Company"},
        )
    )

    assert result.id == order.id
    assert result.status == OrderStatus.ACTIVE.value
    assert result.price == 2500
    assert result.deadline == 3
    assert result.is_enrolled is False
    assert result.is_date_confirmed is False


def test_create_order_rejects_finished_existing_order(db_session):
    client = _create_client(db_session, "client-finished")
    request = _create_request(db_session, client_id=client.id, status=0)
    _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-finished",
        client_id=client.guid,
        status=OrderStatus.FINISHED.value,
        enrollment_date=datetime.utcnow(),
        is_enrolled=True,
        is_date_confirmed=True,
    )

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            create_order(
                CreateOrderRequest(
                    receiver_id=client.guid,
                    order_request_id=request.id,
                    price=1100,
                ),
                db=db_session,
                current_user={"id": "company-finished", "user_type": "Company"},
            )
        )
    assert exc_info.value.status_code == 400
    assert "Finished order cannot be updated" in exc_info.value.detail


def test_create_order_validates_request_owner_and_active_status(db_session):
    owner = _create_client(db_session, "owner-guid", email="owner@example.com")
    outsider = _create_client(db_session, "outsider-guid", email="outsider@example.com")

    inactive_request = _create_request(db_session, client_id=owner.id, status=2)
    with pytest.raises(HTTPException) as inactive_exc:
        asyncio.run(
            create_order(
                CreateOrderRequest(
                    receiver_id=owner.guid,
                    order_request_id=inactive_request.id,
                    price=900,
                ),
                db=db_session,
                current_user={"id": "company-1", "user_type": "Company"},
            )
        )
    assert inactive_exc.value.status_code == 400
    assert "not active" in inactive_exc.value.detail

    active_request = _create_request(db_session, client_id=owner.id, status=0)
    with pytest.raises(HTTPException) as receiver_exc:
        asyncio.run(
            create_order(
                CreateOrderRequest(
                    receiver_id=outsider.guid,
                    order_request_id=active_request.id,
                    price=900,
                ),
                db=db_session,
                current_user={"id": "company-1", "user_type": "Company"},
            )
        )
    assert receiver_exc.value.status_code == 400
    assert "does not match order request owner" in receiver_exc.value.detail


def test_confirm_and_enroll_require_active_order(db_session):
    client = _create_client(db_session, "client-active-checks")
    request = _create_request(db_session, client_id=client.id, status=0)

    canceled_order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-1",
        client_id=client.guid,
        status=OrderStatus.CANCELED.value,
        enrollment_date=datetime.utcnow() + timedelta(days=1),
    )
    with pytest.raises(HTTPException) as canceled_exc:
        asyncio.run(
            confirm_enrollment_date(
                canceled_order.id,
                db=db_session,
                current_user={"id": client.guid, "user_type": "Client"},
            )
        )
    assert canceled_exc.value.status_code == 400

    finished_order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-2",
        client_id=client.guid,
        status=OrderStatus.FINISHED.value,
        enrollment_date=datetime.utcnow() + timedelta(days=1),
        is_enrolled=True,
        is_date_confirmed=True,
    )
    with pytest.raises(HTTPException) as finished_exc:
        asyncio.run(
            enroll(
                finished_order.id,
                db=db_session,
                current_user={"id": client.guid, "user_type": "Client"},
            )
        )
    assert finished_exc.value.status_code == 400


def test_confirm_enrollment_supports_legacy_active_status_without_date(db_session):
    client = _create_client(db_session, "client-legacy-active")
    request = _create_request(db_session, client_id=client.id, status=0)
    legacy_order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-legacy",
        client_id=client.guid,
        status=0,
        enrollment_date=None,
        is_enrolled=False,
        is_date_confirmed=False,
    )

    confirmed = asyncio.run(
        confirm_enrollment_date(
            legacy_order.id,
            db=db_session,
            current_user={"id": client.guid, "user_type": "Client"},
        )
    )

    assert confirmed.status == OrderStatus.ACTIVE.value
    assert confirmed.is_enrolled is True
    assert confirmed.is_date_confirmed is True


def test_change_enrollment_date_requires_active_order(db_session):
    client = _create_client(db_session, "client-change-check")
    request = _create_request(db_session, client_id=client.id, status=0)
    canceled_order = _create_order(
        db_session,
        order_request_id=request.id,
        company_id="company-1",
        client_id=client.guid,
        status=OrderStatus.CANCELED.value,
        enrollment_date=datetime.utcnow() + timedelta(days=1),
    )

    with pytest.raises(HTTPException) as exc_info:
        asyncio.run(
            change_enrollment_date(
                ChangeEnrollmentDateRequest(
                    order_id=canceled_order.id,
                    enrollment_date=datetime.utcnow() + timedelta(days=2),
                ),
                db=db_session,
                current_user={"id": "company-1", "user_type": "Company"},
            )
        )
    assert exc_info.value.status_code == 400
