"""Tests for the active client request flow."""

import pytest
from fastapi import status

from services.authentication.models import UserType

from tests.helpers import create_client_profile, create_order_request, create_user


@pytest.mark.client
class TestClientService:
    """Validate current client endpoints against the live service contract."""

    def test_get_client_returns_existing_profile(
        self,
        client_client,
        client_token,
        test_client_user,
        test_db,
    ):
        create_client_profile(
            test_db,
            test_client_user,
            name="Test",
            surname="Client",
        )

        response = client_client.get(
            "/api/client/get",
            headers={"Authorization": f"Bearer {client_token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["guid"] == str(test_client_user.id)
        assert data["email"] == test_client_user.email
        assert data["coordinates"] == "55.7558,37.6173"

    def test_get_client_autocreates_profile_from_user(
        self,
        client_client,
        client_token,
        test_client_user,
        mock_geocode,
    ):
        response = client_client.get(
            "/api/client/get",
            headers={"Authorization": f"Bearer {client_token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["guid"] == str(test_client_user.id)
        assert data["email"] == test_client_user.email
        assert data["coordinates"] == "55.7558,37.6173"
        assert data["phone_number"] == "0000000000"
        assert data["city"] == "-"
        mock_geocode.assert_called_once_with("-", "-")

    def test_get_clients_admin(self, client_client, admin_token):
        response = client_client.get(
            "/api/client/getClients",
            headers={"Authorization": f"Bearer {admin_token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), list)

    def test_change_user_data(
        self,
        client_client,
        client_token,
        test_client_user,
        test_db,
        mock_geocode,
    ):
        create_client_profile(
            test_db,
            test_client_user,
            name="Old",
            surname="Name",
            city="Old City",
            street="Old Street",
        )

        response = client_client.put(
            "/api/client/changeUserData",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "name": "New",
                "surname": "Name",
                "email": "newemail@test.com",
                "phone_number": "+9876543210",
                "city": "New City",
                "street": "New Street",
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["name"] == "New"
        assert data["city"] == "New City"
        assert data["street"] == "New Street"
        assert data["coordinates"] == "55.7558,37.6173"
        mock_geocode.assert_called_once_with("New City", "New Street")

    def test_send_order_request(
        self,
        client_client,
        client_token,
        test_client_user,
        test_db,
    ):
        create_client_profile(test_db, test_client_user)

        response = client_client.post(
            "/api/client/sendOrderRequest",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "category_id": 1,
                "description": "Test order request",
                "search_radius": 5000,
                "to_know_price": True,
                "to_know_deadline": False,
                "to_know_specialist": True,
                "to_know_enrollment_date": True,
                "photo_uris": [],
            },
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["description"] == "Test order request"
        assert data["category_id"] == 1
        assert data["to_know_price"] == "true"
        assert data["to_know_deadline"] == "false"
        assert data["to_know_specialist"] == "true"

    def test_get_client_requests_returns_only_current_user_requests(
        self,
        client_client,
        client_token,
        test_client_user,
        test_db,
    ):
        current_client = create_client_profile(test_db, test_client_user, name="Current")
        create_order_request(test_db, current_client, description="Current request")

        other_user = create_user(
            test_db,
            email="other-client@test.com",
            user_type=UserType.CLIENT,
            user_name="Other Client",
        )
        other_client = create_client_profile(test_db, other_user, name="Other")
        create_order_request(test_db, other_client, description="Other request")

        response = client_client.get(
            "/api/client/getClientRequests",
            headers={"Authorization": f"Bearer {client_token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert len(data) == 1
        assert data[0]["description"] == "Current request"
        assert data[0]["client_guid"] == str(test_client_user.id)

    def test_change_icon_uri(
        self,
        client_client,
        client_token,
        test_client_user,
        test_db,
    ):
        create_client_profile(test_db, test_client_user)

        response = client_client.put(
            "/api/client/changeIconUri?uri=https://example.com/icon.png",
            headers={"Authorization": f"Bearer {client_token}"},
        )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["icon_uri"] == "https://example.com/icon.png"
