from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app import models, schemas
from geoalchemy2.shape import from_shape
from shapely.geometry import Point
from passlib.context import CryptContext
import sqlalchemy as sa
from app.utils.geocode import geocode_address

 
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ——— Utility password —————————————————————————————
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)


# ——— CRUD Clienti (Users) ——————————————————————————
async def get_user_by_email(db: AsyncSession, email: str):
    result = await db.execute(select(models.User).filter(models.User.email == email))
    return result.scalars().first()

async def create_user(db: AsyncSession, user: schemas.UserCreate):
    hashed_pw = get_password_hash(user.password)
    db_user = models.User(
        email=user.email,
        full_name=user.full_name,
        hashed_password=hashed_pw
    )
    db.add(db_user)
    await db.commit()
    await db.refresh(db_user)
    return db_user

# ——— CRUD VendorAccount (auth) ————————————————————————
async def get_vendor_account_by_email(db: AsyncSession, email: str):
    result = await db.execute(select(models.VendorAccount).filter(models.VendorAccount.email == email))
    return result.scalars().first()

async def create_vendor_account(db: AsyncSession, account: schemas.VendorAccountCreate):
    hashed_pw = get_password_hash(account.password)
    db_account = models.VendorAccount(
        email=account.email,
        hashed_password=hashed_pw
    )
    db.add(db_account)
    await db.commit()
    await db.refresh(db_account)
    return db_account

# ——— CRUD Vendor Profile ——————————————————————————
async def create_vendor_profile(db: AsyncSession, vendor: schemas.VendorCreate, account_id: int):
    # 1) geocoding dell'indirizzo (assumi che geocode_address ritorni lat, lon)
    lat, lon = await geocode_address(
        country=vendor.country,
        city=vendor.city,
        postcode=vendor.postcode,
        address=vendor.address
    )
    # 2) costruisci il POINT PostGIS
    point = from_shape(Point(lon, lat), srid=4326)

    # 3) crea il record vendor con location
    db_vendor = models.Vendor(
        account_id=account_id,
        company_name=vendor.company_name,
        category=vendor.category,
        country=vendor.country,
        city=vendor.city,
        postcode=vendor.postcode,
        address=vendor.address,
        location=point
    )
    db.add(db_vendor)
    await db.commit()
    await db.refresh(db_vendor)
    return db_vendor


async def get_vendor_profile_by_account_id(db: AsyncSession, account_id: int):
    result = await db.execute(select(models.Vendor).filter(models.Vendor.account_id == account_id))
    return result.scalars().first()





async def search_vendors(
    db: AsyncSession,
    city: str | None = None,
    postcode: str | None = None,
    address: str | None = None
) -> list[models.Vendor]:
    stmt = select(models.Vendor)
    if city:
        stmt = stmt.filter(models.Vendor.city.ilike(f"%{city}%"))
    if postcode:
        stmt = stmt.filter(models.Vendor.postcode.ilike(f"%{postcode}%"))
    if address:
        stmt = stmt.filter(models.Vendor.address.ilike(f"%{address}%"))
    result = await db.execute(stmt)
    return result.scalars().all()