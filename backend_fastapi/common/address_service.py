"""Сервис для работы с адресами и геокодированием"""
import httpx
from typing import Tuple
from pydantic_settings import BaseSettings
import hashlib

class AddressServiceSettings(BaseSettings):
    geocoding_api_key: str | None = None
    geocoding_api_url: str = "https://geocode-maps.yandex.ru/1.x"
    
    class Config:
        env_file = ".env"
        case_sensitive = False
        extra = "ignore"  # Игнорировать дополнительные поля из .env

settings = AddressServiceSettings()

def _clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(value, max_value))

def _deterministic_coords(city: str, street: str) -> str:
    """Детерминированный fallback, если внешнее геокодирование недоступно.

    Возвращает стабильные координаты для одинакового адреса, чтобы радиусные
    фильтры продолжали работать даже без доступа к внешним API.
    """
    city_key = (city or "").strip().lower()
    street_key = (street or "").strip().lower()

    city_hash = int(hashlib.sha256(city_key.encode("utf-8")).hexdigest(), 16)
    street_hash = int(hashlib.sha256(street_key.encode("utf-8")).hexdigest(), 16)

    # Базовая точка (Москва), смещения для разных городов и улиц
    base_lat = 55.751244
    base_lon = 37.618423

    city_lat_offset = ((city_hash % 1400) / 100.0) - 7.0      # [-7, +7]
    city_lon_offset = (((city_hash >> 11) % 3000) / 100.0) - 15.0  # [-15, +15]
    street_lat_offset = ((street_hash % 1000) / 10000.0) - 0.05    # [-0.05, +0.05]
    street_lon_offset = (((street_hash >> 9) % 1000) / 10000.0) - 0.05

    lat = _clamp(base_lat + city_lat_offset + street_lat_offset, -85.0, 85.0)
    lon = _clamp(base_lon + city_lon_offset + street_lon_offset, -180.0, 180.0)

    return f"{lat:.6f},{lon:.6f}"

async def geocode(city: str, street: str) -> str:
    """Геокодирование адреса (получение координат)"""
    address = f"{city}, {street}".strip(", ")
    
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
                # Yandex: pos хранится как "lon lat"
                members = (data.get("response", {})
                              .get("GeoObjectCollection", {})
                              .get("featureMember", []))
                if members:
                    pos = (members[0].get("GeoObject", {})
                                   .get("Point", {})
                                   .get("pos", ""))
                    parts = pos.split()
                    if len(parts) == 2:
                        lon, lat = parts
                        return f"{float(lat):.6f},{float(lon):.6f}"
            except Exception:
                pass

    # Fallback без API-ключа: OpenStreetMap Nominatim
    try:
        async with httpx.AsyncClient(
            timeout=8.0,
            headers={"User-Agent": "choice-app/1.0 (geocoding)"},
        ) as client:
            response = await client.get(
                "https://nominatim.openstreetmap.org/search",
                params={"q": address, "format": "json", "limit": 1},
            )
            if response.status_code == 200:
                data = response.json()
                if isinstance(data, list) and data:
                    lat = float(data[0]["lat"])
                    lon = float(data[0]["lon"])
                    return f"{lat:.6f},{lon:.6f}"
    except Exception:
        pass

    # Локальный deterministic fallback (вместо единой "точки Москвы")
    return _deterministic_coords(city, street)

async def get_distance(address1: Tuple[str, str], address2: Tuple[str, str]) -> int:
    """Получение расстояния между двумя адресами в метрах"""
    # TODO: Интегрировать с реальным API расчета расстояния
    # Пока возвращаем заглушку
    return 1000  # 1 км по умолчанию
