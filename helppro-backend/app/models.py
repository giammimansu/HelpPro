from sqlalchemy import Column, Integer, String, Boolean, Enum
import enum
from app.database import Base

class RoleEnum(str, enum.Enum):
    client = "client"
    professional = "professional"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    full_name = Column(String, nullable=True)
    hashed_password = Column(String, nullable=False)
    disabled = Column(Boolean, default=False)
    role = Column(Enum(RoleEnum), default=RoleEnum.client, nullable=False)