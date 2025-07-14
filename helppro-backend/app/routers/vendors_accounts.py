# app/routers/vendor_accounts.py

from fastapi import APIRouter, Depends, UploadFile, File, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
import csv
from io import StringIO

from app import crud, schemas
from app.database import get_db

router = APIRouter(
    prefix="/vendors/accounts",
    tags=["vendor-accounts"]
)

@router.post(
    "/bulk-upload",
    response_model=List[schemas.VendorAccountOut],
    status_code=status.HTTP_201_CREATED
)
async def bulk_upload_vendor_accounts(
    file: UploadFile = File(..., description="CSV header: email,password"),
    db: AsyncSession = Depends(get_db)
):
    if not file.filename.lower().endswith(".csv"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Richiesto file .csv"
        )

    content = await file.read()
    text = content.decode("utf-8")
    reader = csv.DictReader(StringIO(text))

    created = []
    errors = []

    for idx, row in enumerate(reader, start=1):
        try:
            acc_in = schemas.VendorAccountCreate(
                email=row["email"],
                password=row["password"]
            )
            acc = await crud.create_vendor_account(db, acc_in)
            created.append(acc)
        except Exception as e:
            errors.append(f"Riga {idx}: {e}")

    if errors:
        raise HTTPException(
            status_code=status.HTTP_207_MULTI_STATUS,
            detail={"created": [a.id for a in created], "errors": errors}
        )

    return created
