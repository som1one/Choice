"""Test fixtures shared by backend FastAPI test suites."""

import sys
import uuid
from pathlib import Path
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

current_file = Path(__file__).resolve()
project_root = current_file.parent.parent
if str(project_root) not in sys.path:
    sys.path.insert(0, str(project_root))

from common.database import Base, get_db
from common.security import create_access_token, get_password_hash

from sqlalchemy import create_engine as sa_create_engine

TEST_DATABASE_URL = "sqlite:///:memory:"
test_engine_for_models = sa_create_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

import common.database

original_engine = common.database.engine
common.database.engine = test_engine_for_models

from services.authentication.models import UserType
from services.authentication.main import app as auth_app
from services.category_service.main import app as category_app
from services.chat.main import app as chat_app
from services.client_service.main import app as client_app
from services.company_service.main import app as company_app
from services.file_service.main import app as file_app
from services.ordering.main import app as ordering_app
from services.review_service.main import app as review_app

common.database.engine = original_engine


@pytest.fixture(scope="function")
def test_db():
    """Create an isolated in-memory SQLite database for each test."""
    test_engine = create_engine(
        TEST_DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )

    # Import models so every table is registered in Base.metadata.
    from services.authentication.models import User
    from services.category_service.models import Category
    from services.chat.models import ChatUser, Message
    from services.client_service.models import Client, OrderRequest
    from services.company_service.models import Company
    from services.ordering.models import Order
    from services.review_service.models import Review

    Base.metadata.create_all(bind=test_engine)
    TestingSessionLocal = sessionmaker(
        autocommit=False,
        autoflush=False,
        bind=test_engine,
        expire_on_commit=False,
    )

    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        Base.metadata.drop_all(bind=test_engine)


@pytest.fixture
def override_get_db(test_db):
    """Override get_db for app-level tests."""

    def _get_db():
        try:
            yield test_db
        finally:
            pass

    return _get_db


@pytest.fixture
def auth_client(override_get_db):
    auth_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(auth_app)
    yield client
    auth_app.dependency_overrides.clear()


@pytest.fixture
def company_client(override_get_db):
    company_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(company_app)
    yield client
    company_app.dependency_overrides.clear()


@pytest.fixture
def client_client(override_get_db):
    client_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(client_app)
    yield client
    client_app.dependency_overrides.clear()


@pytest.fixture
def category_client(override_get_db):
    category_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(category_app)
    yield client
    category_app.dependency_overrides.clear()


@pytest.fixture
def ordering_client(override_get_db):
    ordering_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(ordering_app)
    yield client
    ordering_app.dependency_overrides.clear()


@pytest.fixture
def review_client(override_get_db):
    review_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(review_app)
    yield client
    review_app.dependency_overrides.clear()


@pytest.fixture
def chat_client(override_get_db):
    chat_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(chat_app)
    yield client
    chat_app.dependency_overrides.clear()


@pytest.fixture
def file_client(override_get_db):
    file_app.dependency_overrides[get_db] = override_get_db
    client = TestClient(file_app)
    yield client
    file_app.dependency_overrides.clear()


@pytest.fixture
def test_admin_user(test_db):
    from services.authentication.models import User

    admin = User(
        id=uuid.UUID("00000000-0000-0000-0000-000000000001"),
        email="admin@test.com",
        password_hash=get_password_hash("admin123"),
        user_type=UserType.ADMIN,
        user_name="Admin User",
    )
    test_db.add(admin)
    test_db.commit()
    return admin


@pytest.fixture
def test_client_user(test_db):
    from services.authentication.models import User

    client = User(
        id=uuid.uuid4(),
        email="client@test.com",
        password_hash=get_password_hash("client123"),
        user_type=UserType.CLIENT,
        user_name="Test Client",
    )
    test_db.add(client)
    test_db.commit()
    return client


@pytest.fixture
def test_company_user(test_db):
    from services.authentication.models import User

    company = User(
        id=uuid.uuid4(),
        email="company@test.com",
        password_hash=get_password_hash("company123"),
        user_type=UserType.COMPANY,
        user_name="Test Company",
    )
    test_db.add(company)
    test_db.commit()
    return company


@pytest.fixture
def admin_token(test_admin_user):
    return create_access_token(
        data={
            "id": str(test_admin_user.id),
            "email": test_admin_user.email,
            "user_type": "Admin",
            "address": None,
        }
    )


@pytest.fixture
def client_token(test_client_user):
    return create_access_token(
        data={
            "id": str(test_client_user.id),
            "email": test_client_user.email,
            "user_type": "Client",
            "address": None,
        }
    )


@pytest.fixture
def company_token(test_company_user):
    return create_access_token(
        data={
            "id": str(test_company_user.id),
            "email": test_company_user.email,
            "user_type": "Company",
            "address": None,
        }
    )


@pytest.fixture
def mock_rabbitmq():
    with patch("common.rabbitmq_service.publish_event_sync") as mock:
        yield mock


@pytest.fixture
def mock_push_notification():
    with patch("common.push_notification_service.send_push_notification") as mock:
        yield mock


@pytest.fixture
def mock_geocode():
    with patch("common.address_service.geocode") as mock:
        with patch("services.client_service.routers.client.geocode", new=mock):
            with patch("services.company_service.routers.company.geocode", new=mock):
                mock.return_value = "55.7558,37.6173"
                yield mock
