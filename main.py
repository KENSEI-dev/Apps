from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import random

app = FastAPI()

# CORS for Flutter
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"status": "FastAPI Sleep Tracker LIVE!"}

@app.get("/test")  # Your working test endpoint
async def test():
    return {"ping": "pong", "from": "FastAPI"}

# 🔥 SLEEP ANALYTICS ENDPOINT (Flutter needs this!)
@app.get("/api/sleep/analytics/{user_id}")
async def get_sleep_analytics(user_id: str):
    # Generate realistic sleep data
    sessions = []
    for i in range(7):
        duration = round(random.uniform(4.5, 9.5), 1)
        sessions.append({
            "date": f"2026-02-{27-i:02d}",
            "duration": duration,
            "quality": round(random.uniform(6.0, 9.5), 1)
        })
    
    total_sleep = sum(s["duration"] for s in sessions)
    avg_sleep = round(total_sleep / 7, 1)
    
    # 🐻 Sleep Animal Logic
    if avg_sleep > 8.0:
        sleep_animal = "🐻 Bear"
        insight = "Deep hibernation sleep! Peak energy tomorrow."
    elif avg_sleep > 7.0:
        sleep_animal = "🦉 Owl"
        insight = "Quality-focused sleep. Sharp focus ahead."
    else:
        sleep_animal = "😺 Cat"
        insight = "Nap specialist. Agile but fragmented rest."
    
    return {
        "user_id": user_id,
        "total_sleep_hours": round(total_sleep, 1),
        "average_sleep_hours": avg_sleep,
        "sleep_animal": sleep_animal,
        "insight": insight,
        "sessions": sessions
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
