# app/utils/geocode.py
import httpx

async def geocode_address(
    country: str,
    city: str,
    postcode: str,
    address: str
) -> tuple[float, float]:
    """
    Geocodifica un indirizzo completo usando Nominatim e ritorna (lat, lon).
    Solleva un’eccezione se non trova risultati.
    """
    query = f"{address}, {postcode} {city}, {country}"
    url = "https://nominatim.openstreetmap.org/search"
    params = {
        "q": query,
        "format": "json",
        "limit": 1,
    }
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(url, params=params, headers={
            "User-Agent": "HelpProApp/1.0 (+https://your.domain)"
        })
        resp.raise_for_status()
        data = resp.json()
        if not data:
            raise ValueError(f"Indirizzo non trovato: {query}")
        lat = float(data[0]["lat"])
        lon = float(data[0]["lon"])
        return lat, lon
