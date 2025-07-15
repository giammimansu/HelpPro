# app/routers/vendors.py

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from fastapi import Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import Session
from typing import List, Tuple
import csv
from io import StringIO

from app import crud, schemas
from app.database import get_db
from app.models import VendorAccount
from geoalchemy2.shape import to_shape

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
    summary="Cerca professionisti nel raggio specificato",
)
async def search_vendors(
    lat: float = Query(..., description="Latitudine"),
    lon: float = Query(..., description="Longitudine"),
    radius_km: float = Query(5.0, gt=0.0, description="Raggio di ricerca in km"),
    db: AsyncSession = Depends(get_db),
):
    vendors = await crud.get_vendors_in_radius(db, lat, lon, radius_km)
    out: List[schemas.VendorOut] = []
    for v in vendors:
        if v.location is None:
            continue
        # to_shape converte il GeometryElement in uno shape shapely, 
        # ma puoi pure usare v.location.x / .y se funziona
        geom = to_shape(v.location)
        out.append(schemas.VendorOut(
            id=v.id,
            account_id=v.account_id,
            company_name=v.company_name,
            category=v.category,
            country=v.country,
            city=v.city,
            postcode=v.postcode,
            address=v.address,
            latitude=geom.y,    # latitudine
            longitude=geom.x,   # longitudine
        ))
    return out