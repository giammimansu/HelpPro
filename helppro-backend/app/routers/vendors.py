# app/routers/vendors.py

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import csv
from io import StringIO

from app import crud, schemas
from app.database import get_db
from app.models import VendorAccount

router = APIRouter(prefix="/vendors", tags=["vendors"])

@router.post(
    "/bulk-upload",
    response_model=List[schemas.VendorOut],
    status_code=status.HTTP_201_CREATED
)
async def bulk_upload_vendors(
    file: UploadFile = File(
        ...,
        description="CSV file with header: account_id,company_name,category,country,city,postcode,address"
    ),
    db: AsyncSession = Depends(get_db)
):
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="È richiesto un file .csv"
        )

    text = (await file.read()).decode("utf-8")
    reader = csv.DictReader(StringIO(text))

    created: List[schemas.VendorOut] = []
    errors: List[str] = []

    for idx, row in enumerate(reader, start=1):
        try:
            account_id = int(row["account_id"])
            acc = await db.get(VendorAccount, account_id)
            if not acc:
                raise ValueError(f"account_id {account_id} non trovato")

            vin = schemas.VendorCreate(
                company_name=row["company_name"],
                category=row["category"],
                country=row["country"],
                city=row["city"],
                postcode=row["postcode"],
                address=row["address"]
            )
            v = await crud.create_vendor_profile(db, vin, account_id)
            created.append(v)

        except Exception as e:
            errors.append(f"Riga {idx}: {e}")

    if errors:
        # ⚠️ qui **alza** l'eccezione, non la restituisce
        raise HTTPException(
            status_code=status.HTTP_207_MULTI_STATUS,
            detail={"created": [v.id for v in created], "errors": errors}
        )

    return created



@router.get(
    "/search",
    response_model=List[schemas.VendorOut],
    status_code=status.HTTP_200_OK
)
async def search_vendors(
    city: str | None    = Query(None, description="Filtra per città"),
    postcode: str | None= Query(None, description="Filtra per CAP"),
    address: str | None = Query(None, description="Filtra per indirizzo/via"),
    db: AsyncSession = Depends(get_db)
):
    vendors = await crud.search_vendors(db, city, postcode, address)
    return vendors