from pydantic import BaseModel, EmailStr
from typing import Literal, Tuple
from typing import Optional
import enum

class CategoryEnum(str, enum.Enum):
    haircut = "haircut"
    beautician = "beautician"
    plumber = "plumber"
    mason = "mason"

class VendorAccountCreate(BaseModel):
    email: EmailStr
    password: str

class VendorAccountOut(BaseModel):
    id: int
    email: EmailStr

    class Config:
        orm_mode = True

# --- Schemi profilo Vendor ---
class VendorBase(BaseModel):
    company_name: str
    category: CategoryEnum
    country: str
    city: str
    postcode: str
    address: str

class VendorCreate(VendorBase):
    pass


class VendorOut(BaseModel):
    id: int
    account_id: int
    company_name: str
    category: str
    country: str
    city: str
    postcode: str
    address: str
    latitude: float
    longitude: float

    class Config:
        orm_mode = True

#################
# --- Schemi profilo Utente ---
#################


class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class User(UserBase):
    id: int
    disabled: Optional[bool] = None

    class Config:
        orm_mode = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None


