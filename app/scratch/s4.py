import os
from dotenv import load_dotenv
load_dotenv()
key = os.getenv("GOOGLE_PLACES_KEY")
print("key loaded" if key else "key missing")