from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from app import models, schemas
from passlib.context import CryptContext

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
    db_vendor = models.Vendor(
        account_id=account_id,
        company_name=vendor.company_name,
        category=vendor.category,
        country=vendor.country,
        city=vendor.city,
        postcode=vendor.postcode,
        address=vendor.address
    )
    db.add(db_vendor)
    await db.commit()
    await db.refresh(db_vendor)
    return db_vendor

async def get_vendor_profile_by_account_id(db: AsyncSession, account_id: int):
    result = await db.execute(select(models.Vendor).filter(models.Vendor.account_id == account_id))
    return result.scalars().first()