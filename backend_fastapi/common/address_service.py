"""Сервис для работы с адресами и геокодированием"""
import httpx
from typing import Tuple
from pydantic_settings import BaseSettings

class AddressServiceSettings(BaseSettings):
    geocoding_api_key: str | None = None
    geocoding_api_url: str = "https://geocode-maps.yandex.ru/1.x"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

settings = AddressServiceSettings()

async def geocode(city: str, street: str) -> str:
    """Геокодирование адреса (получение координат)"""
    # TODO: Интегрировать с реальным API геокодирования
    # Пока возвращаем заглушку
    address = f"{city}, {street}"
    
    if settings.geocoding_api_key:
        async with httpx.AsyncClient() as client:
            try:
                response = await client.get(
                    settings.geocoding_api_url,
                    params={
                        "apikey": settings.geocoding_api_key,
                        "geocode": address,
                        "format": "json"
                    }
                )
                data = response.json()
                # Извлечь координаты из ответа
                # return f"{lon},{lat}"
            except Exception:
                pass
    
    # Заглушка: возвращаем координаты Москвы
    return "55.7558,37.6173"

async def get_distance(address1: Tuple[str, str], address2: Tuple[str, str]) -> int:
    """Получение расстояния между двумя адресами в метрах"""
    # TODO: Интегрировать с реальным API расчета расстояния
    # Пока возвращаем заглушку
    return 1000  # 1 км по умолчанию
