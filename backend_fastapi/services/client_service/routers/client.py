"""Роутеры для Client Service"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from common.database import get_db
from common.dependencies import get_current_user, require_admin
from common.address_service import geocode
from ..models import Client, OrderRequest
from ..schemas import (
    ClientResponse, ChangeUserDataRequest,
    OrderRequestResponse, SendOrderRequestRequest, ChangeOrderRequestRequest
)
from ..repositories import ClientRepository, OrderRequestRepository
import json

router = APIRouter(prefix="/api/client", tags=["client"])

@router.get("/get", response_model=ClientResponse)
async def get_client(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение данных клиента"""
    user_id = current_user["id"]
    repository = ClientRepository(db)
    client = await repository.get(user_id)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    return client

@router.get("/getClients", response_model=list[ClientResponse])
async def get_clients(
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение всех клиентов (админ)"""
    repository = ClientRepository(db)
    clients = await repository.get_all()
    return clients

@router.get("/getClientAdmin", response_model=ClientResponse)
async def get_client_admin(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Получение клиента по GUID (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    return client

@router.put("/changeUserData", response_model=ClientResponse)
async def change_user_data(
    request: ChangeUserDataRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение данных клиента"""
    user_id = current_user["id"]
    repository = ClientRepository(db)
    client = await repository.get(user_id)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    client.name = request.name
    client.surname = request.surname
    client.email = request.email
    client.phone_number = request.phone_number
    client.city = request.city
    client.street = request.street
    client.coordinates = coords
    
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update client"
        )
    
    # TODO: Отправить событие UserDataChangedEvent в RabbitMQ
    
    return client

@router.put("/changeUserDataAdmin", response_model=ClientResponse)
async def change_user_data_admin(
    guid: str,
    request: ChangeUserDataRequest,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение данных клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    # Геокодирование адреса
    coords = await geocode(request.city, request.street)
    
    # Обновление данных
    client.name = request.name
    client.surname = request.surname
    client.email = request.email
    client.phone_number = request.phone_number
    client.city = request.city
    client.street = request.street
    client.coordinates = coords
    
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update client"
        )
    
    # TODO: Отправить событие UserDataChangedEvent в RabbitMQ
    
    return client

@router.put("/changeIconUri", response_model=ClientResponse)
async def change_icon_uri(
    uri: str,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение иконки клиента"""
    user_id = current_user["id"]
    repository = ClientRepository(db)
    client = await repository.get(user_id)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.icon_uri = uri
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # TODO: Отправить событие UserIconUriChangedEvent в RabbitMQ
    
    return client

@router.put("/changeIconUriAdmin", response_model=ClientResponse)
async def change_icon_uri_admin(
    guid: str,
    uri: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Изменение иконки клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    client.icon_uri = uri
    result = await repository.update(client)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update icon"
        )
    
    # TODO: Отправить событие UserIconUriChangedEvent в RabbitMQ
    
    return client

@router.delete("/deleteClientAdmin")
async def delete_client_admin(
    guid: str,
    db: Session = Depends(get_db),
    admin: dict = Depends(require_admin)
):
    """Удаление клиента (админ)"""
    repository = ClientRepository(db)
    client = await repository.get(guid)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    db.delete(client)
    db.commit()
    
    # TODO: Отправить событие UserDeletedEvent в RabbitMQ
    
    return {"message": "Client deleted successfully"}

@router.post("/sendOrderRequest", response_model=OrderRequestResponse)
async def send_order_request(
    request: SendOrderRequestRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Создание заявки на заказ"""
    user_id = current_user["id"]
    client_repo = ClientRepository(db)
    client = await client_repo.get(user_id)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    repo = OrderRequestRepository(db)
    order_request = OrderRequest(
        client_id=client.id,
        category_id=request.category_id,
        description=request.description,
        search_radius=request.search_radius,
        to_know_price="true" if request.to_know_price else "false",
        to_know_deadline="true" if request.to_know_deadline else "false",
        to_know_enrollment_date="true" if request.to_know_enrollment_date else "false",
        photo_uris=json.dumps(request.photo_uris) if request.photo_uris else None,
        status=0  # Active
    )
    
    order_request = await repo.add(order_request)
    
    # TODO: Отправить событие OrderRequestSentEvent в RabbitMQ
    
    return order_request

@router.get("/getOrderRequests", response_model=list[OrderRequestResponse])
async def get_order_requests(
    category_id: int | None = None,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявок"""
    repo = OrderRequestRepository(db)
    
    if category_id:
        requests = await repo.get_by_category(category_id)
    else:
        user_id = current_user["id"]
        client_repo = ClientRepository(db)
        client = await client_repo.get(user_id)
        if client:
            requests = await repo.get_by_client(client.id)
        else:
            requests = []
    
    return requests

@router.get("/getClientRequests", response_model=list[OrderRequestResponse])
async def get_client_requests(
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявок клиента"""
    user_id = current_user["id"]
    client_repo = ClientRepository(db)
    client = await client_repo.get(user_id)
    
    if not client:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Client not found"
        )
    
    repo = OrderRequestRepository(db)
    requests = await repo.get_by_client(client.id)
    
    return requests

@router.get("/getRequest", response_model=OrderRequestResponse)
async def get_request(
    request_id: int,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Получение заявки по ID"""
    repo = OrderRequestRepository(db)
    request = await repo.get(request_id)
    
    if not request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order request not found"
        )
    
    return request

@router.put("/changeOrderRequest", response_model=OrderRequestResponse)
async def change_order_request(
    request: ChangeOrderRequestRequest,
    db: Session = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    """Изменение заявки"""
    repo = OrderRequestRepository(db)
    order_request = await repo.get(request.id)
    
    if not order_request:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Order request not found"
        )
    
    # Обновление данных
    order_request.category_id = request.category_id
    order_request.description = request.description
    order_request.search_radius = request.search_radius
    order_request.to_know_price = "true" if request.to_know_price else "false"
    order_request.to_know_deadline = "true" if request.to_know_deadline else "false"
    order_request.to_know_enrollment_date = "true" if request.to_know_enrollment_date else "false"
    order_request.photo_uris = json.dumps(request.photo_uris) if request.photo_uris else None
    
    result = await repo.update(order_request)
    
    if not result:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to update order request"
        )
    
    return order_request
