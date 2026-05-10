"""Тесты для API фраз отзывов."""

from fastapi import status

from services.company_service.models_rating import RatingCriterion


class TestRatingCriteriaService:
    def test_admin_crud_grouped_by_grade(self, company_client, admin_token):
        create_response = company_client.post(
            "/api/rating-criteria/",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "grade": 1,
                "text": "Очень плохо",
                "sort_order": 10,
                "is_active": True,
            },
        )
        assert create_response.status_code == status.HTTP_200_OK
        created = create_response.json()
        assert created["grade"] == 1
        assert created["text"] == "Очень плохо"

        duplicate_response = company_client.post(
            "/api/rating-criteria/",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "grade": 1,
                "text": "Очень плохо",
            },
        )
        assert duplicate_response.status_code == status.HTTP_400_BAD_REQUEST

        another_grade_response = company_client.post(
            "/api/rating-criteria/",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "grade": 5,
                "text": "Очень плохо",
            },
        )
        assert another_grade_response.status_code == status.HTTP_200_OK

        filtered_response = company_client.get("/api/rating-criteria/?grade=1&is_active=true")
        assert filtered_response.status_code == status.HTTP_200_OK
        filtered_items = filtered_response.json()
        assert len(filtered_items) == 1
        assert filtered_items[0]["text"] == "Очень плохо"

        update_response = company_client.put(
            f"/api/rating-criteria/{created['id']}",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "grade": 1,
                "text": "Плохо",
                "sort_order": 5,
                "is_active": False,
            },
        )
        assert update_response.status_code == status.HTTP_200_OK
        updated = update_response.json()
        assert updated["text"] == "Плохо"
        assert updated["is_active"] is False

        inactive_response = company_client.get("/api/rating-criteria/?grade=1&is_active=false")
        assert inactive_response.status_code == status.HTTP_200_OK
        assert inactive_response.json()[0]["id"] == created["id"]

        delete_response = company_client.delete(
            f"/api/rating-criteria/{created['id']}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert delete_response.status_code == status.HTTP_200_OK

    def test_get_all_returns_sorted_by_grade_and_sort_order(self, company_client, test_db):
        test_db.add_all(
            [
                RatingCriterion(grade=5, text="Отлично", sort_order=20, is_active=True),
                RatingCriterion(grade=1, text="Плохо", sort_order=10, is_active=True),
                RatingCriterion(grade=5, text="Супер", sort_order=5, is_active=True),
            ]
        )
        test_db.commit()

        response = company_client.get("/api/rating-criteria/")
        assert response.status_code == status.HTTP_200_OK
        payload = response.json()
        assert [item["text"] for item in payload] == ["Плохо", "Супер", "Отлично"]
