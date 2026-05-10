"""Тесты для Chat Service"""
import pytest
from fastapi import status
from services.chat.models import Message, MessageType, ChatUser
from unittest.mock import patch, AsyncMock

@pytest.mark.chat
class TestChatService:
    """Тесты сервиса чата"""
    
    def test_send_message(self, chat_client, client_token, test_client_user, test_db):
        """Тест отправки сообщения"""
        import uuid
        from services.authentication.models import User, UserType
        
        # Создаем получателя
        receiver_user = User(
            id=uuid.uuid4(),
            email="receiver@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Receiver"
        )
        test_db.add(receiver_user)
        test_db.commit()
        
        # Мокаем WebSocket отправку
        with patch('services.chat.routers.message.send_message_to_user', new_callable=AsyncMock):
            response = chat_client.post(
                "/api/message/send",
                headers={"Authorization": f"Bearer {client_token}"},
                json={
                    "receiver_id": str(receiver_user.id),
                    "text": "Hello, world!"
                }
            )
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            assert data["text"] == "Hello, world!"
            assert data["message_type"] == MessageType.TEXT.value
    
    def test_send_image(self, chat_client, client_token, test_client_user, test_db):
        """Тест отправки изображения"""
        import uuid
        from services.authentication.models import User, UserType
        
        receiver_user = User(
            id=uuid.uuid4(),
            email="imagereceiver@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Image Receiver"
        )
        test_db.add(receiver_user)
        test_db.commit()
        
        with patch('services.chat.routers.message.send_message_to_user', new_callable=AsyncMock):
            response = chat_client.post(
                "/api/message/sendImage",
                headers={"Authorization": f"Bearer {client_token}"},
                json={
                    "receiver_id": str(receiver_user.id),
                    "uri": "https://example.com/image.jpg"
                }
            )
            assert response.status_code == status.HTTP_200_OK
            data = response.json()
            assert data["text"] == "https://example.com/image.jpg"
            assert data["message_type"] == MessageType.IMAGE.value
    
    def test_get_messages(self, chat_client, client_token, test_client_user, test_db):
        """Тест получения сообщений"""
        import uuid
        from services.authentication.models import User, UserType
        
        receiver_user = User(
            id=uuid.uuid4(),
            email="getmessages@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Messages Receiver"
        )
        test_db.add(receiver_user)
        test_db.commit()
        
        # Создаем сообщение
        message = Message(
            sender_id=str(test_client_user.id),
            receiver_id=str(receiver_user.id),
            text="Test message",
            message_type=MessageType.TEXT.value
        )
        test_db.add(message)
        test_db.commit()
        
        response = chat_client.get(
            f"/api/message/getMessages?receiver_id={str(receiver_user.id)}",
            headers={"Authorization": f"Bearer {client_token}"}
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert isinstance(data, list)
        assert len(data) > 0
    
    def test_read_message(self, chat_client, client_token, test_client_user, test_db):
        """Тест отметки сообщения как прочитанного"""
        import uuid
        from services.authentication.models import User, UserType
        
        receiver_user = User(
            id=uuid.uuid4(),
            email="readreceiver@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Read Receiver"
        )
        test_db.add(receiver_user)
        test_db.commit()
        
        # Создаем сообщение
        message = Message(
            sender_id=str(receiver_user.id),
            receiver_id=str(test_client_user.id),
            text="Unread message",
            message_type=MessageType.TEXT.value,
            is_read=False
        )
        test_db.add(message)
        test_db.commit()
        
        with patch('services.chat.routers.message.send_message_to_user', new_callable=AsyncMock):
            response = chat_client.put(
                f"/api/message/read?message_id={message.id}",
                headers={"Authorization": f"Bearer {client_token}"}
            )
            assert response.status_code == status.HTTP_200_OK
    
    def test_get_chat(self, chat_client, client_token, test_client_user, test_db):
        """Тест получения чата с пользователем"""
        import uuid
        from services.authentication.models import User, UserType
        
        chat_user_obj = User(
            id=uuid.uuid4(),
            email="chatuser@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Chat User"
        )
        test_db.add(chat_user_obj)
        test_db.commit()
        
        # Создаем ChatUser
        chat_user = ChatUser(
            guid=str(chat_user_obj.id),
            name="Chat User",
            icon_uri="https://example.com/icon.png",
            status="Online"
        )
        test_db.add(chat_user)
        test_db.commit()
        
        response = chat_client.get(
            f"/api/message/getChat?user_id={str(chat_user_obj.id)}",
            headers={"Authorization": f"Bearer {client_token}"}
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data["name"] == "Chat User"
        assert "messages" in data
    
    def test_get_chats(self, chat_client, client_token, test_client_user, test_db):
        """Тест получения всех чатов"""
        import uuid
        from services.authentication.models import User, UserType
        
        other_user = User(
            id=uuid.uuid4(),
            email="other@test.com",
            password_hash="hash",
            user_type=UserType.CLIENT,
            user_name="Other User"
        )
        test_db.add(other_user)
        test_db.commit()
        
        # Создаем сообщение для создания чата
        message = Message(
            sender_id=str(test_client_user.id),
            receiver_id=str(other_user.id),
            text="Chat message",
            message_type=MessageType.TEXT.value
        )
        test_db.add(message)
        test_db.commit()
        
        # Создаем ChatUser
        chat_user = ChatUser(
            guid=str(other_user.id),
            name="Other User",
            icon_uri="https://example.com/icon.png",
            status="Offline"
        )
        test_db.add(chat_user)
        test_db.commit()
        
        response = chat_client.get(
            "/api/message/getChats",
            headers={"Authorization": f"Bearer {client_token}"}
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert isinstance(data, list)
