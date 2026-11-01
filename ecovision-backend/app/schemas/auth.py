from datetime import datetime
from typing import Optional
from pydantic import BaseModel, ConfigDict


class UserCreate(BaseModel):
    name: str
    email: str
    password: str
    role: Optional[str] = "citizen"


class UserLogin(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: str


class TokenData(BaseModel):
    user_id: Optional[int] = None
    role: Optional[str] = None


class TokenRefresh(BaseModel):
    refresh_token: str


class UserUpdate(BaseModel):
    name: Optional[str] = None
    language_preference: Optional[str] = "en"


class UserRoleUpdate(BaseModel):
    role: str


class UserOut(BaseModel):
    id: int
    name: str
    email: str
    role: str
    is_active: bool
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
