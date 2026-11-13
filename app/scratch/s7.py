import os
import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, Query, HTTPException

from s6 import parse_place

load_dotenv()
KEY = os.getenv("GOOGLE_PLACES_KEY")
URL = "https://places.googleapis.com/v1/places:searchNearby"
FIELD_MASK = ("places.id,places.displayName,places.rating,"
            "places.userRatingCount,places.formattedAddress,places.location,"
            "places.currentOpeningHours.openNow,places.priceLevel")

app = FastAPI()


def search_nearby(lat, lng, radius):
    """Call Google and return the raw list of places."""
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": KEY,
        "X-Goog-FieldMask": FIELD_MASK,
    }
    body = {
        "includedTypes": ["restaurant"],
        "maxResultCount": 20,
        "locationRestriction": {"circle": {
            "center": {"latitude": lat, "longitude": lng},
            "radius": float(radius),
        }},
    }
    r = httpx.post(URL, headers=headers, json=body, timeout=10)
    if r.status_code != 200:
        raise HTTPException(502, "Upstream service failed")
    return r.json().get("places", [])


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/api/restaurants")
def restaurants(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius: int = Query(1500, ge=100, le=5000),
):
    try:
        raw_places = search_nearby(lat, lng, radius)
    except httpx.HTTPError:
        raise HTTPException(502, "Upstream service failed")

    results = [parse_place(p, lat, lng) for p in raw_places]
    results.sort(key=lambda p: (p["distance_m"] is None, p["distance_m"] or 0))
    return {"count": len(results), "results": results}