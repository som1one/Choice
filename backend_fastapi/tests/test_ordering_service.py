"""Tests for the current inquiry-to-order backend flow."""

from datetime import datetime, timedelta

import pytest
from fastapi import status

from services.authentication.models import UserType
from services.ordering.models import Order, OrderStatus

from tests.helpers import (
    build_token,
    create_client_profile,
    create_company_profile,
    create_order,
    create_order_request,
    create_user,
)


@pytest.mark.ordering
class TestOrderingService:
    """Exercise the active order lifecycle used by the Flutter app."""

    def test_company_can_create_and_update_order_response(
        self,
        ordering_client,
        company_token,
        test_company_user,
        test_client_user,
        test_db,
    ):
        create_company_profile(test_db, test_company_user, categories_id=[1])
        client = create_client_profile(test_db, test_client_user)
        order_request = create_order_request(
            test_db,
            client,
            category_id=1,
            description="Need an electrician",
        )

        first_response = ordering_client.post(
            "/api/order/create",
            headers={"Authorization": f"Bearer {company_token}"},
            json={
                "order_request_id": order_request.id,
                "receiver_id": str(client.guid),
                "price": 1000,
                "prepayment": 500,
                "deadline": 7,
                "response_text": "Can take it this week",
                "specialist_name": "Ivan",
                "specialist_phone": "+79999999999",
                "enrollment_date": "2026-06-01T12:00:00",
            },
        )

        assert first_response.status_code == status.HTTP_200_OK
        created = first_response.json()
        assert created["price"] == 1000
        assert created["status"] == OrderStatus.ACTIVE.value
        assert created["company_id"] == str(test_company_user.id)
        assert created["client_id"] == str(test_client_user.id)
        assert created["is_enrolled"] is False

        second_response = ordering_client.post(
            "/api/order/create",
            headers={"Authorization": f"Bearer {company_token}"},
            json={
                "order_request_id": order_request.id,
                "receiver_id": str(client.guid),
                "price": 1800,
                "prepayment": 900,
                "deadline": 10,
                "response_text": "Updated offer",
                "specialist_name": "Petr",
                "specialist_phone": "+78888888888",
                "enrollment_date": "2026-06-03T15:30:00",
            },
        )

        assert second_response.status_code == status.HTTP_200_OK
        updated = second_response.json()
        assert updated["id"] == created["id"]
        assert updated["price"] == 1800
        assert updated["deadline"] == 10
        assert updated["response_text"] == "Updated offer"
        assert updated["specialist_name"] == "Petr"
        assert updated["is_date_confirmed"] is False

    def test_get_orders_filters_by_current_participant(
        self,
        ordering_client,
        company_token,
        client_token,
        test_company_user,
        test_client_user,
        test_db,
    ):
        create_company_profile(test_db, test_company_user, categories_id=[1])
        client = create_client_profile(test_db, test_client_user)
        request = create_order_request(test_db, client)
        expected_order = create_order(
            test_db,
            order_request_id=request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
        )

        other_company_user = create_user(
            test_db,
            email="other-company@test.com",
            user_type=UserType.COMPANY,
            user_name="Other Company",
        )
        create_company_profile(test_db, other_company_user, categories_id=[1])
        other_client_user = create_user(
            test_db,
            email="other-order-client@test.com",
            user_type=UserType.CLIENT,
            user_name="Other Order Client",
        )
        other_client = create_client_profile(test_db, other_client_user)
        other_request = create_order_request(test_db, other_client)
        create_order(
            test_db,
            order_request_id=other_request.id,
            company_id=str(other_company_user.id),
            client_id=str(other_client_user.id),
        )

        company_response = ordering_client.get(
            "/api/order/get",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert company_response.status_code == status.HTTP_200_OK
        company_orders = company_response.json()
        assert [order["id"] for order in company_orders] == [expected_order.id]

        client_response = ordering_client.get(
            "/api/order/get",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert client_response.status_code == status.HTTP_200_OK
        client_orders = client_response.json()
        assert [order["id"] for order in client_orders] == [expected_order.id]

    def test_full_inquiry_lifecycle_and_review_eligibility(
        self,
        client_client,
        company_client,
        ordering_client,
        client_token,
        company_token,
        test_client_user,
        test_company_user,
        test_db,
    ):
        client = create_client_profile(test_db, test_client_user)
        create_company_profile(test_db, test_company_user, categories_id=[1])

        created_request_response = client_client.post(
            "/api/client/sendOrderRequest",
            headers={"Authorization": f"Bearer {client_token}"},
            json={
                "category_id": 1,
                "description": "Full lifecycle request",
                "search_radius": 20000,
                "to_know_price": True,
                "to_know_deadline": True,
                "to_know_specialist": True,
                "to_know_enrollment_date": True,
                "photo_uris": [],
            },
        )
        assert created_request_response.status_code == status.HTTP_200_OK
        request_payload = created_request_response.json()
        request_id = request_payload["id"]

        client_requests_response = client_client.get(
            "/api/client/getClientRequests",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert client_requests_response.status_code == status.HTTP_200_OK
        client_requests = client_requests_response.json()
        assert any(item["id"] == request_id for item in client_requests)

        company_requests_response = company_client.get(
            "/api/company/getOrderRequests",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert company_requests_response.status_code == status.HTTP_200_OK
        company_requests = company_requests_response.json()
        assert any(item["id"] == request_id for item in company_requests)

        create_order_response = ordering_client.post(
            "/api/order/create",
            headers={"Authorization": f"Bearer {company_token}"},
            json={
                "order_request_id": request_id,
                "receiver_id": str(client.guid),
                "price": 2400,
                "prepayment": 1200,
                "deadline": 5,
                "response_text": "We can start tomorrow",
                "specialist_name": "Sergey",
                "specialist_phone": "+70000000000",
                "enrollment_date": "2026-06-05T10:00:00",
            },
        )
        assert create_order_response.status_code == status.HTTP_200_OK
        created_order = create_order_response.json()
        order_id = created_order["id"]

        client_visible_orders_response = ordering_client.get(
            f"/api/order/get?order_request_id={request_id}",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert client_visible_orders_response.status_code == status.HTTP_200_OK
        visible_orders = client_visible_orders_response.json()
        assert len(visible_orders) == 1
        assert visible_orders[0]["id"] == order_id
        assert visible_orders[0]["is_enrolled"] is False

        confirm_response = ordering_client.put(
            f"/api/order/confirmEnrollmentDate?order_id={order_id}",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert confirm_response.status_code == status.HTTP_200_OK
        confirmed_order = confirm_response.json()
        assert confirmed_order["is_enrolled"] is True
        assert confirmed_order["is_date_confirmed"] is True
        assert confirmed_order["status"] == OrderStatus.ACTIVE.value

        company_orders_response = ordering_client.get(
            "/api/order/get",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert company_orders_response.status_code == status.HTTP_200_OK
        company_orders = company_orders_response.json()
        assert company_orders[0]["id"] == order_id
        assert company_orders[0]["is_date_confirmed"] is True

        finish_response = ordering_client.put(
            f"/api/order/finishOrder?order_id={order_id}",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert finish_response.status_code == status.HTTP_200_OK
        finished_order = finish_response.json()
        assert finished_order["status"] == OrderStatus.FINISHED.value

        review_check_response = ordering_client.put(
            (
                "/api/order/addReview"
                f"?client_id={test_client_user.id}"
                f"&company_id={test_company_user.id}"
                f"&reviewer_id={test_client_user.id}"
                "&reserve=false"
            ),
        )
        assert review_check_response.status_code == status.HTTP_200_OK
        assert review_check_response.json()["success"] is True
        persisted_after_check = test_db.query(Order).filter(Order.id == order_id).first()
        assert persisted_after_check is not None
        assert persisted_after_check.reviews == []

        review_reserve_response = ordering_client.put(
            (
                "/api/order/addReview"
                f"?client_id={test_client_user.id}"
                f"&company_id={test_company_user.id}"
                f"&reviewer_id={test_client_user.id}"
                "&reserve=true"
            ),
        )
        assert review_reserve_response.status_code == status.HTTP_200_OK
        assert review_reserve_response.json()["success"] is True
        persisted_after_reserve = test_db.query(Order).filter(Order.id == order_id).first()
        assert persisted_after_reserve is not None
        assert persisted_after_reserve.reviews == [str(test_client_user.id)]

        duplicate_review_response = ordering_client.put(
            (
                "/api/order/addReview"
                f"?client_id={test_client_user.id}"
                f"&company_id={test_company_user.id}"
                f"&reviewer_id={test_client_user.id}"
                "&reserve=true"
            ),
        )
        assert duplicate_review_response.status_code == status.HTTP_200_OK
        assert duplicate_review_response.json()["success"] is False

    def test_new_finished_order_can_still_be_reviewed_after_old_reviewed_order(
        self,
        ordering_client,
        test_client_user,
        test_company_user,
        test_db,
    ):
        client = create_client_profile(test_db, test_client_user)
        create_company_profile(test_db, test_company_user, categories_id=[1])

        old_request = create_order_request(
            test_db,
            client,
            category_id=1,
            description="Old reviewed request",
        )
        old_order = create_order(
            test_db,
            order_request_id=old_request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
            status=OrderStatus.FINISHED.value,
            reviews=[str(test_client_user.id)],
        )

        new_request = create_order_request(
            test_db,
            client,
            category_id=1,
            description="New finished request",
        )
        new_order = create_order(
            test_db,
            order_request_id=new_request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
            status=OrderStatus.FINISHED.value,
            reviews=[],
        )

        review_check_response = ordering_client.put(
            (
                "/api/order/addReview"
                f"?client_id={test_client_user.id}"
                f"&company_id={test_company_user.id}"
                f"&reviewer_id={test_client_user.id}"
                "&reserve=false"
            ),
        )
        assert review_check_response.status_code == status.HTTP_200_OK
        assert review_check_response.json()["success"] is True

        persisted_old = test_db.query(Order).filter(Order.id == old_order.id).first()
        persisted_new = test_db.query(Order).filter(Order.id == new_order.id).first()
        assert persisted_old is not None
        assert persisted_new is not None
        assert persisted_old.reviews == [str(test_client_user.id)]
        assert persisted_new.reviews == []

        review_reserve_response = ordering_client.put(
            (
                "/api/order/addReview"
                f"?client_id={test_client_user.id}"
                f"&company_id={test_company_user.id}"
                f"&reviewer_id={test_client_user.id}"
                "&reserve=true"
            ),
        )
        assert review_reserve_response.status_code == status.HTTP_200_OK
        assert review_reserve_response.json()["success"] is True

        persisted_old = test_db.query(Order).filter(Order.id == old_order.id).first()
        persisted_new = test_db.query(Order).filter(Order.id == new_order.id).first()
        assert persisted_old is not None
        assert persisted_new is not None
        assert persisted_old.reviews == [str(test_client_user.id)]
        assert persisted_new.reviews == [str(test_client_user.id)]

    def test_non_participant_cannot_change_order_state(
        self,
        ordering_client,
        company_token,
        test_company_user,
        test_client_user,
        test_db,
    ):
        client = create_client_profile(test_db, test_client_user)
        create_company_profile(test_db, test_company_user, categories_id=[1])
        request = create_order_request(test_db, client)
        order = create_order(
            test_db,
            order_request_id=request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
            enrollment_date=datetime.utcnow() + timedelta(days=1),
        )

        outsider = create_user(
            test_db,
            email="outsider@test.com",
            user_type=UserType.CLIENT,
            user_name="Outsider",
        )
        outsider_token = build_token(outsider)

        enroll_response = ordering_client.put(
            f"/api/order/enroll?order_id={order.id}",
            headers={"Authorization": f"Bearer {outsider_token}"},
        )
        assert enroll_response.status_code == status.HTTP_403_FORBIDDEN

        finish_response = ordering_client.put(
            f"/api/order/finishOrder?order_id={order.id}",
            headers={"Authorization": f"Bearer {outsider_token}"},
        )
        assert finish_response.status_code == status.HTTP_403_FORBIDDEN

        cancel_response = ordering_client.put(
            f"/api/order/cancelEnrollment?order_id={order.id}",
            headers={"Authorization": f"Bearer {outsider_token}"},
        )
        assert cancel_response.status_code == status.HTTP_403_FORBIDDEN

    def test_terminal_state_rules_for_finished_and_canceled_orders(
        self,
        ordering_client,
        company_token,
        client_token,
        test_company_user,
        test_client_user,
        test_db,
    ):
        client = create_client_profile(test_db, test_client_user)
        create_company_profile(test_db, test_company_user, categories_id=[1])
        request = create_order_request(test_db, client)

        canceled_order = create_order(
            test_db,
            order_request_id=request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
            status=OrderStatus.CANCELED.value,
        )
        canceled_finish_response = ordering_client.put(
            f"/api/order/finishOrder?order_id={canceled_order.id}",
            headers={"Authorization": f"Bearer {company_token}"},
        )
        assert canceled_finish_response.status_code == status.HTTP_400_BAD_REQUEST

        canceled_enroll_response = ordering_client.put(
            f"/api/order/enroll?order_id={canceled_order.id}",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert canceled_enroll_response.status_code == status.HTTP_400_BAD_REQUEST

        finished_request = create_order_request(
            test_db,
            client,
            description="Finished request",
        )
        finished_order = create_order(
            test_db,
            order_request_id=finished_request.id,
            company_id=str(test_company_user.id),
            client_id=str(test_client_user.id),
            status=OrderStatus.FINISHED.value,
            is_enrolled=True,
            is_date_confirmed=True,
            enrollment_date=datetime.utcnow(),
        )
        finished_cancel_response = ordering_client.put(
            f"/api/order/cancelEnrollment?order_id={finished_order.id}",
            headers={"Authorization": f"Bearer {client_token}"},
        )
        assert finished_cancel_response.status_code == status.HTTP_400_BAD_REQUEST
