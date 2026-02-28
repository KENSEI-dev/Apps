from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime, timedelta

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

@app.get("/")
async def root(): return {"status": "OK"}

@app.get("/api/sleep/add/{minutes}")
async def add_sleep(minutes: int):
    now = datetime.now()
    
    # Simple state (no globals needed)
    if 'reset_time' not in globals() or globals()['reset_time'].minute != now.minute:
        globals()['total_minutes'] = minutes
        globals()['reset_time'] = now
    else:
        globals()['total_minutes'] += minutes
    
    total = globals()['total_minutes']
    
    # Compact animal logic
    animal = "🐻 Bear" if total >= 480 else "🦉 Owl" if total >= 420 else "😺 Cat"
    
    return {"total_minutes": total, "animal": animal}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
