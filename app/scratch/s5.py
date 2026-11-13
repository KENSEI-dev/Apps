import os, json, httpx
from dotenv import load_dotenv
load_dotenv()
KEY=os.getenv("GOOGLE_PLACES_KEY")
URL ="hettps://places.googleapis.com/v1/places:searchNearby"
headers={
    "Cotent-Type": "application/json",
    "X-Goog-Api-Key": KEY,
    "X-Goog-FieldMask": ("places.id,places.displayName,places.rating,"
        "places.userRatingCount,places.formattedAddress,places.location,"
        "places.currentOpeningHours.openNow,places.priceLevel"),
}
body={
    "includedTypes":["restaurant"],
    "maxResultCount": 20,
    "locationRestriction":{"circle":{
        "center":{"latitude": 22.5726, "longitude": 88.3639},
        "radius":1500.0,
    }},

}
r=httpx.post(URL, header=headers, json=body, timeout=10)
print("status:",r.status_code)
data=r.json()
places=data.get("places")
if places is None:
    print(data)
else:
    print("count:",len(places))
    print(json.dumps(places[:2], indent=2))