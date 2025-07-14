# app/models.py

from sqlalchemy import Column, Integer, String, Boolean, Enum, ForeignKey
from sqlalchemy.orm import relationship
import enum
from app.database import Base

# — Ruoli utenti (clients) —
class RoleEnum(str, enum.Enum):
    client = "client"
    professional = "professional"

class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String, unique=True, index=True, nullable=False)
    full_name       = Column(String, nullable=True)
    hashed_password = Column(String, nullable=False)
    disabled        = Column(Boolean, default=False)
    role            = Column(Enum(RoleEnum), default=RoleEnum.client, nullable=False)

    # NOTA: nessuna relazione verso Vendor, perché stai tenendo 
    # client e professional separati.


# — Categorie per i professionisti —
class CategoryEnum(str, enum.Enum):
    haircut     = "haircut"
    beautician  = "beautician"
    plumber     = "plumber"
    mason       = "mason"


# — Credenziali vendor (tabella auth) —
class VendorAccount(Base):
    __tablename__ = "vendor_accounts"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)

    # relazione one-to-one col profilo
    vendor_profile = relationship("Vendor", back_populates="account", uselist=False)


# — Profilo dettagliato vendor —
class Vendor(Base):
    __tablename__ = "vendors"

    id          = Column(Integer, primary_key=True, index=True)
    account_id  = Column(Integer, ForeignKey("vendor_accounts.id"), unique=True, nullable=False)
    company_name= Column(String, nullable=False)
    category    = Column(Enum(CategoryEnum), nullable=False)
    country     = Column(String, nullable=False)
    city        = Column(String, nullable=False)
    postcode    = Column(String, nullable=False)
    address     = Column(String, nullable=False)

    account = relationship("VendorAccount", back_populates="vendor_profile")
