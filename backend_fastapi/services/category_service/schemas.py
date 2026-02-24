"""Pydantic схемы для Category Service"""
from pydantic import BaseModel, Field
from typing import Optional

class CategoryBase(BaseModel):
    title: str
    icon_uri: str

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    id: int
    title: str
    icon_uri: str

class CategoryResponse(CategoryBase):
    id: int
    
    class Config:
        from_attributes = True
