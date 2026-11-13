import os
from dotenv import load_dotenv
load_dotenv()
GOOGLE_KEY = os.getenv("GOOGLE_PLACES_KEY")
if not GOOGLE_KEY:
    raise RuntimeError("GOOGLE_PLACES_KEY is not set")
PLACES_URL="https://places.googleapis.com/v1/places:searchNearby"
FIELD_MASK=("places.id,places.displayName,places.rating,"
            "places.userRatingCount,places.formattedAddress,places.location,"
            "places.currentOpeningHours.openNow,places.priceLevel")