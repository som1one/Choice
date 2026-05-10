"""Тесты для Company Service."""

import pytest
from fastapi import status

from services.company_service.models import Company


@pytest.mark.company
class TestCompanyService:
    """Тесты сервиса компаний."""

    def test_get_all_companies(self, company_client, client_token):
        response = company_client.get(
            "/api/company/getAll",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), list)

    def test_get_all_companies_admin(self, company_client, admin_token, test_db):
        company = Company(
            guid="test-company-guid",
            title="Test Company",
            email="company@test.com",
            phone_number="+1234567890",
            city="Moscow",
            street="Test Street",
            coordinates="55.7558,37.6173",
            is_data_filled=False,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.get(
            "/api/company/getAllAdmin",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_get_companies_by_category(self, company_client, client_token, test_db):
        company = Company(
            guid="category-company-guid",
            title="Category Company",
            email="category@test.com",
            phone_number="+1234567890",
            city="Moscow",
            street="Test Street",
            coordinates="55.7558,37.6173",
            categories_id=[1, 2],
            is_data_filled=True,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.get(
            "/api/company/getByCategory?category_id=1",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
        assert isinstance(response.json(), list)

    def test_get_company(self, company_client, company_token, test_company_user, test_db):
        company = Company(
            guid=str(test_company_user.id),
            title="Get Company",
            email=test_company_user.email,
            phone_number="+1234567890",
            city="Moscow",
            street="Test Street",
            coordinates="55.7558,37.6173",
            is_data_filled=True,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.get(
            "/api/company/get",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["guid"] == company.guid
        assert data["title"] == "Get Company"

    def test_fill_company_data(self, company_client, company_token, test_company_user, test_db, mock_geocode):
        company = Company(
            guid=str(test_company_user.id),
            title="Empty Company",
            email=test_company_user.email,
            phone_number="+1234567890",
            city="",
            street="",
            coordinates="55.7558,37.6173",
            is_data_filled=False,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.put(
            "/api/company/fillCompanyData",
            headers={"Authorization": f"Bearer {company_token}"},
            json={
                "site_url": "https://example.com",
                "description": "Test description",
                "social_medias": ["https://vk.com/test"],
                "photo_uris": ["https://example.com/photo.jpg"],
                "categories_id": [1, 2],
                "prepayment_available": True,
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["title"] == "Empty Company"
        assert data["prepayment_available"] is True

    def test_change_company_data(self, company_client, company_token, test_company_user, test_db, mock_geocode):
        company = Company(
            guid=str(test_company_user.id),
            title="Original Company",
            email=test_company_user.email,
            phone_number="+1234567890",
            city="Old City",
            street="Old Street",
            coordinates="55.7558,37.6173",
            is_data_filled=True,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.put(
            "/api/company/changeData",
            headers={"Authorization": f"Bearer {company_token}"},
            json={
                "title": "Changed Company",
                "phone_number": "+1111111111",
                "email": "changed@test.com",
                "site_url": "https://changed.example.com",
                "city": "New City",
                "street": "New Street",
                "social_medias": ["https://vk.com/changed"],
                "photo_uris": ["https://example.com/changed.jpg"],
                "categories_id": [1],
                "description": "Changed description",
                "card_color": "#66CBFF",
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["title"] == "Changed Company"
        assert data["address"]["city"] == "New City"

    def test_change_company_data_admin(self, company_client, admin_token, test_db, mock_geocode):
        company = Company(
            guid="admin-change-guid",
            title="Admin Change Company",
            email="adminchange@test.com",
            phone_number="+1234567890",
            city="Old City",
            street="Old Street",
            coordinates="55.7558,37.6173",
            is_data_filled=True,
        )
        test_db.add(company)
        test_db.commit()

        response = company_client.put(
            "/api/company/changeDataAdmin",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "guid": company.guid,
                "title": "Admin Changed",
                "phone_number": "+2222222222",
                "email": "adminchanged@test.com",
                "site_url": "https://admin.example.com",
                "city": "Admin City",
                "street": "Admin Street",
                "social_medias": ["https://t.me/admincompany"],
                "photo_uris": ["https://example.com/admin.jpg"],
                "categories_id": [1],
                "description": "Admin description",
                "card_color": "#2196F3",
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["title"] == "Admin Changed"

    def test_delete_company_admin(self, company_client, admin_token, test_db):
        company = Company(
            guid="admin-delete-guid",
            title="Delete Company",
            email="delete-company@test.com",
            phone_number="+1234567890",
            city="Moscow",
            street="Delete street",
            coordinates="55.7558,37.6173",
            is_data_filled=True,
        )
        test_db.add(company)
        test_db.commit()

        delete_response = company_client.delete(
            f"/api/company/delete?id={company.guid}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert delete_response.status_code == status.HTTP_200_OK

        repeat_delete_response = company_client.delete(
            f"/api/company/delete?id={company.guid}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert repeat_delete_response.status_code == status.HTTP_404_NOT_FOUND
