"""Тесты для Review Service."""

import uuid
from unittest.mock import AsyncMock, Mock, patch

import pytest
from fastapi import status

from services.authentication.models import User, UserType
from services.company_service.models_rating import RatingCriterion
from services.review_service.models import Review


@pytest.mark.review
class TestReviewService:
    """Тесты сервиса отзывов."""

    def test_get_reviews(self, review_client, test_db):
        sender_id = str(uuid.uuid4())
        receiver_id = str(uuid.uuid4())

        review = Review(
            sender_id=sender_id,
            receiver_id=receiver_id,
            text="Great service!",
            grade=5,
            photo_uris=[],
        )
        test_db.add(review)
        test_db.commit()

        response = review_client.get(f"/api/review/get?guid={receiver_id}")
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_send_review(self, review_client, client_token, test_db):
        company_user = User(
            id=uuid.uuid4(),
            email="reviewcompany@test.com",
            password_hash="hash",
            user_type=UserType.COMPANY,
            user_name="Review Company",
        )
        criterion = RatingCriterion(
            grade=5,
            text="Excellent service",
            sort_order=0,
            is_active=True,
        )
        test_db.add(company_user)
        test_db.add(criterion)
        test_db.commit()

        with patch("httpx.AsyncClient") as mock_client:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"success": True}
            mock_client.return_value.__aenter__.return_value.put = AsyncMock(
                return_value=mock_response
            )

            response = review_client.post(
                "/api/review/send",
                headers={"Authorization": f"Bearer {client_token}"},
                json={
                    "guid": str(company_user.id),
                    "criterion_id": criterion.id,
                    "grade": 5,
                    "photo_uris": [],
                },
            )

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["text"] == criterion.text
        assert data["grade"] == 5

    def test_send_review_to_self(self, review_client, client_token, test_client_user):
        response = review_client.post(
            "/api/review/send",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "guid": str(test_client_user.id),
                "text": "Self review",
                "grade": 5,
                "photo_uris": [],
            },
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_send_review_rejects_phrase_with_wrong_grade(self, review_client, client_token, test_db):
        company_user = User(
            id=uuid.uuid4(),
            email="wronggrade@test.com",
            password_hash="hash",
            user_type=UserType.COMPANY,
            user_name="Wrong Grade",
        )
        criterion = RatingCriterion(
            grade=1,
            text="Плохо",
            sort_order=0,
            is_active=True,
        )
        test_db.add(company_user)
        test_db.add(criterion)
        test_db.commit()

        with patch("httpx.AsyncClient") as mock_client:
            mock_response = Mock()
            mock_response.status_code = 200
            mock_response.json.return_value = {"success": True}
            mock_client.return_value.__aenter__.return_value.put = AsyncMock(
                return_value=mock_response
            )

            response = review_client.post(
                "/api/review/send",
                headers={"Authorization": f"Bearer {client_token}"},
                json={
                    "guid": str(company_user.id),
                    "criterion_id": criterion.id,
                    "grade": 5,
                    "photo_uris": [],
                },
            )

        assert response.status_code == status.HTTP_400_BAD_REQUEST

    def test_edit_review_admin(self, review_client, admin_token, test_db):
        sender_id = str(uuid.uuid4())
        receiver_id = str(uuid.uuid4())

        review = Review(
            sender_id=sender_id,
            receiver_id=receiver_id,
            text="Original review",
            grade=3,
            photo_uris=[],
        )
        test_db.add(review)
        test_db.commit()

        response = review_client.put(
            "/api/review/edit",
            headers={"Authorization": f"Bearer {admin_token}"},
            json={
                "id": review.id,
                "text": "Edited review",
                "grade": 5,
                "photo_uris": [],
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["text"] == "Edited review"
        assert data["grade"] == 5

    def test_get_all_reviews_admin(self, review_client, admin_token, test_db):
        sender_id = str(uuid.uuid4())
        receiver_id = str(uuid.uuid4())

        review = Review(
            sender_id=sender_id,
            receiver_id=receiver_id,
            text="Test review",
            grade=4,
            photo_uris=[],
        )
        test_db.add(review)
        test_db.commit()

        response = review_client.get(
            "/api/review/getAll",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0

    def test_delete_review_admin(self, review_client, admin_token, test_db):
        sender_id = str(uuid.uuid4())
        receiver_id = str(uuid.uuid4())

        review = Review(
            sender_id=sender_id,
            receiver_id=receiver_id,
            text="To delete",
            grade=2,
            photo_uris=[],
        )
        test_db.add(review)
        test_db.commit()

        response = review_client.delete(
            f"/api/review/delete?id={review.id}",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert response.status_code == status.HTTP_200_OK
