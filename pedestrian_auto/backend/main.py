from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from database import SessionLocal, Stop, CrowdReport, engine, PreferenceMode
from pydantic import BaseModel
from typing import List
from datetime import datetime
import uvicorn
from fastapi import WebSocket, WebSocketDisconnect, BackgroundTasks
from routing_service import RoutingService

app = FastAPI(title="CrowdAvoid API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

active_connections: List[WebSocket] = []

async def broadcast_crowd_update(report_dict):
    dead = []
    for ws in active_connections:
        try:
            await ws.send_json(report_dict)
        except WebSocketDisconnect:
            dead.append(ws)
    for ws in dead:
        if ws in active_connections:
            active_connections.remove(ws)

# ==================== PYDANTIC MODELS ====================
class CrowdReportCreate(BaseModel):
    stop_id: int
    crowd_level: int
    latitude: float
    longitude: float
    timestamp: str = None

class CrowdReportResponse(BaseModel):
    id: int
    stop_id: int
    crowd_level: int
    timestamp: str

class StopResponse(BaseModel):
    id: int
    name: str
    route: str
    latitude: float
    longitude: float
    base_fare: float

class RouteOptionResponse(BaseModel):
    mode: str
    stops: List[dict]
    total_distance_km: float
    estimated_time_minutes: float
    fare: float
    comfort_score: float
    stop_sequence: List[int]

class AllRoutesResponse(BaseModel):
    comfort: RouteOptionResponse
    budget: RouteOptionResponse
    fastest: RouteOptionResponse

# ==================== DEPENDENCY ====================
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ==================== EXISTING ENDPOINTS ====================
@app.get("/api/stops", response_model=List[StopResponse])
def get_stops(db: Session = Depends(get_db)):
    stops = db.query(Stop).all()
    return stops

@app.post("/api/report/crowd", response_model=CrowdReportResponse)
def report_crowd(
    report: CrowdReportCreate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    db_report = CrowdReport(
        stop_id=report.stop_id,
        crowd_level=report.crowd_level,
        latitude=report.latitude,
        longitude=report.longitude,
        timestamp=datetime.utcnow()
    )
    db.add(db_report)
    db.commit()
    db.refresh(db_report)
    data = {
        "id": db_report.id,
        "stop_id": db_report.stop_id,
        "crowd_level": db_report.crowd_level,
        "latitude": db_report.latitude,
        "longitude": db_report.longitude,
        "timestamp": db_report.timestamp.isoformat(),
    }
    background_tasks.add_task(broadcast_crowd_update, data)
    return data

@app.get("/api/stops/nearby")
def get_nearby_stops(lat: float, lon: float, db: Session = Depends(get_db)):
    stops = db.query(Stop).all()
    nearby = []
    for stop in stops:
        distance = ((stop.latitude - lat) ** 2 + (stop.longitude - lon) ** 2) ** 0.5
        if distance < 0.01:
            nearby.append(stop)
    return nearby

# ==================== NEW ROUTING ENDPOINTS ====================
@app.get("/api/route/all", response_model=AllRoutesResponse)
def get_all_routes(
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    db: Session = Depends(get_db)
):
    """Get all 3 route options: comfort, budget, fastest"""
    routing = RoutingService(db)
    routes = routing.find_all_routes(start_lat, start_lon, end_lat, end_lon)
    return routes

@app.get("/api/route/comfort")
def get_comfort_route(
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    db: Session = Depends(get_db)
):
    """Comfort mode: Less crowded, ignore fare/time"""
    routing = RoutingService(db)
    return routing.find_comfort_route(start_lat, start_lon, end_lat, end_lon)

@app.get("/api/route/budget")
def get_budget_route(
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    db: Session = Depends(get_db)
):
    """Budget mode: Cheapest fare, may have crowded stops"""
    routing = RoutingService(db)
    return routing.find_budget_route(start_lat, start_lon, end_lat, end_lon)

@app.get("/api/route/fastest")
def get_fastest_route(
    start_lat: float,
    start_lon: float,
    end_lat: float,
    end_lon: float,
    db: Session = Depends(get_db)
):
    """Fastest mode: Shortest time, fewest stops"""
    routing = RoutingService(db)
    return routing.find_fastest_route(start_lat, start_lon, end_lat, end_lon)

@app.get("/api/traffic/analysis")
def get_traffic_analysis(db: Session = Depends(get_db)):
    """Get real-time traffic analysis across all stops"""
    stops = db.query(Stop).all()
    analysis = {
        "timestamp": datetime.utcnow().isoformat(),
        "stops": []
    }
    
    routing = RoutingService(db)
    for stop in stops:
        avg_crowd = routing._get_average_crowd_level(stop.id)
        analysis["stops"].append({
            "id": stop.id,
            "name": stop.name,
            "crowd_level": avg_crowd,
            "latitude": stop.latitude,
            "longitude": stop.longitude,
        })
    
    return analysis

# ==================== WEBSOCKET ====================
@app.websocket("/ws/crowd")
async def crowd_ws(websocket: WebSocket):
    await websocket.accept()
    active_connections.append(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        active_connections.remove(websocket)

# ==================== STARTUP ====================
@app.on_event("startup")
def create_demo_stops():
    db = SessionLocal()
    db.query(Stop).delete()
    db.commit()
    
    demo_stops = [
        Stop(name="Esplanade", route="Bus 123", latitude=22.5726, longitude=88.3639, base_fare=15),
        Stop(name="Howrah Station", route="Bus 456", latitude=22.5654, longitude=88.3407, base_fare=20),
        Stop(name="Salt Lake", route="Metro Blue", latitude=22.5764, longitude=88.4139, base_fare=25),
        Stop(name="Park Circus", route="Bus 789", latitude=22.5486, longitude=88.3764, base_fare=12),
        Stop(name="Sealdah", route="Metro Green", latitude=22.5644, longitude=88.3635, base_fare=18),
        Stop(name="Kolkata Airport", route="Express 101", latitude=22.6522, longitude=88.4467, base_fare=50),
    ]
    db.add_all(demo_stops)
    db.commit()
    print("✅ Added 6 demo Kolkata stops")
    db.close()

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)