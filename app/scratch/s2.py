from fastapi import FastAPI, Query
app=FastAPI()
@app.get("/echo")
def echo(lat: float = Query(..., ge=-90, le=90),
    lng: float= Query(..., ge=-100, le=180)):
    return {"lat": lat, "lng": lng}