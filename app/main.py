import httpx
from fastapi import FastAPI, Query, HTTPException
from .places import search_nearby, parse_place, UpstreamError

app=FastAPI(title="Swiggy-lite")

@app.get("/health")
def health():
    return{"status":"ok"}

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