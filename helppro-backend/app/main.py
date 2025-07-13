from fastapi import FastAPI
from app.config import settings
from app.database import engine, Base
from app.auth import router as auth_router

app = FastAPI(title="HelpPro Backend")

@app.on_event("startup")
async def on_startup():
    # Crea le tabelle al riavvio senza bloccare l'event loop
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

# Monta il router di auth
app.include_router(auth_router)