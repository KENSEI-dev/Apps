from s3 import haversine_m

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

if __name__ == "__main__":
    full = {"id": "a1", "displayName": {"text": "Cafe One"}, "rating": 4.4,
            "userRatingCount": 120, "formattedAddress": "1 Park St",
            "location": {"latitude": 22.5744, "longitude": 88.3629},
            "currentOpeningHours": {"openNow": True},
            "priceLevel": "PRICE_LEVEL_MODERATE"}
    sparse = {"id": "b2", "displayName": {"text": "New Place"},
            "location": {"latitude": 22.5700, "longitude": 88.3600}}
    print(parse_place(full, 22.5726, 88.3639))
    print(parse_place(sparse, 22.5726, 88.3639))