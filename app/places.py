import httpx
from .config import GOOGLE_KEY, PLACES_URL, FIELD_MASK
from .geo import haversine_m

class UpstreamError(Exception):
    """Google answered with an error"""

def parse_place(raw, user_lat, user_lng):
    loc = raw.get("location", {})
    lat = loc.get("latitude")
    lng = loc.get("longitude")
    distance = None
    if lat is not None and lng is not None:
        distance = round(haversine_m(user_lat, user_lng, lat, lng))
    return {
        "id": raw.get("id"),
        "name": raw.get("displayName", {}).get("text"),
        "rating": raw.get("rating"),
        "rating_count": raw.get("userRatingCount", 0),
        "address": raw.get("formattedAddress"),
        "lat": lat,
        "lng": lng,
        "open_now": raw.get("currentOpeningHours", {}).get("openNow"),
        "price_level": raw.get("priceLevel"),
        "distance_m": distance,
    }


def search_nearby(lat, lng, radius):
    """Call Google and return the raw list of places."""
    headers = {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": GOOGLE_KEY,
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
    r = httpx.post(PLACES_URL, headers=headers, json=body, timeout=10)
    if r.status_code != 200:
        raise UpstreamError(502, "Upstream service failed")
    return r.json().get("places", [])