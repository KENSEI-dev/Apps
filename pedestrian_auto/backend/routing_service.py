from database import SessionLocal, Stop, CrowdReport, Transport, Route, JourneyLeg, RouteOption, PreferenceMode
from datetime import datetime, timedelta
from typing import List, Dict, Tuple
import math
import json

class RoutingService:
    """Core routing engine with 3 preference algorithms"""
    
    def __init__(self, db):
        self.db = db
    
    # ==================== HELPERS ====================
    def _haversine_distance(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates in km"""
        R = 6371  # Earth radius in km
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        a = math.sin(dlat/2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
        return R * c
    
    def _get_average_crowd_level(self, stop_id: int, minutes_ago: int = 30) -> int:
        """Get average crowd level for a stop in last N minutes"""
        cutoff_time = datetime.utcnow() - timedelta(minutes=minutes_ago)
        reports = self.db.query(CrowdReport).filter(
            CrowdReport.stop_id == stop_id,
            CrowdReport.timestamp >= cutoff_time
        ).all()
        
        if not reports:
            return 0  # No data = empty
        return int(sum(r.crowd_level for r in reports) / len(reports))
    
    def _find_nearest_stops(self, lat: float, lon: float, count: int = 3) -> List[Stop]:
        """Find N nearest stops to given coordinates"""
        stops = self.db.query(Stop).all()
        distances = [
            (stop, self._haversine_distance(lat, lon, stop.latitude, stop.longitude))
            for stop in stops
        ]
        distances.sort(key=lambda x: x[1])
        return [stop for stop, _ in distances[:count]]
    
    def _calculate_fare(self, distance_km: float, transport_type: str, crowd_level: int) -> float:
        """Calculate fare based on distance, transport type, and crowd"""
        base_fare = 15.0
        per_km_fare = 5.0
        
        fare = base_fare + (distance_km * per_km_fare)
        
        # Crowd surge pricing (optional, can disable)
        # if crowd_level == 2:
        #     fare *= 1.1  # +10% during peak
        
        return round(fare, 2)
    
    def _calculate_comfort_score(self, stop_ids: List[int]) -> float:
        """Calculate comfort (0-1) based on average crowd levels on route"""
        if not stop_ids:
            return 1.0
        levels = [self._get_average_crowd_level(sid) for sid in stop_ids]
        avg_level = sum(levels) / len(levels)
        # Convert: 0=full comfort (1.0), 2=no comfort (0.0)
        return max(0.0, min(1.0, 1.0 - (avg_level / 2.0)))
    
    # ==================== ROUTING ALGORITHMS ====================
    
    def find_comfort_route(self, start_lat: float, start_lon: float, 
                          end_lat: float, end_lon: float) -> Dict:
        """
        COMFORT MODE: Prioritize less crowded stops, ignore fare/time
        Algorithm: Dijkstra-like with crowd as weight (lower crowd = lower cost)
        """
        start_stops = self._find_nearest_stops(start_lat, start_lon, 2)
        end_stops = self._find_nearest_stops(end_lat, end_lon, 2)
        
        if not start_stops or not end_stops:
            return {"error": "No nearby stops found"}
        
        start_stop = start_stops[0]
        end_stop = end_stops[0]
        
        # Simple comfort route: direct route with least crowded stops
        all_stops = self.db.query(Stop).all()
        
        # Filter stops roughly between start and end (within bounding box)
        min_lat = min(start_lat, end_lat) - 0.01
        max_lat = max(start_lat, end_lat) + 0.01
        min_lon = min(start_lon, end_lon) - 0.01
        max_lon = max(start_lon, end_lon) + 0.01
        
        candidate_stops = [
            s for s in all_stops 
            if min_lat <= s.latitude <= max_lat and min_lon <= s.longitude <= max_lon
        ]
        
        # Sort by least crowd
        candidate_stops.sort(key=lambda s: self._get_average_crowd_level(s.id))
        
        route_stops = candidate_stops[:5]  # Pick top 5 least crowded
        if end_stop not in route_stops:
            route_stops.append(end_stop)
        
        stop_ids = [s.id for s in route_stops]
        distance = self._calculate_total_distance(route_stops)
        time_minutes = distance * 2.5  # Assume 2.5 min per km
        fare = self._calculate_fare(distance, "bus", 0)
        comfort = self._calculate_comfort_score(stop_ids)
        
        return {
            "mode": "comfort",
            "stops": [{"id": s.id, "name": s.name, "lat": s.latitude, "lon": s.longitude} for s in route_stops],
            "total_distance_km": round(distance, 2),
            "estimated_time_minutes": round(time_minutes, 1),
            "fare": fare,
            "comfort_score": round(comfort, 2),
            "stop_sequence": stop_ids
        }
    
    def find_budget_route(self, start_lat: float, start_lon: float, 
                         end_lat: float, end_lon: float) -> Dict:
        """
        BUDGET MODE: Prioritize cheapest fare, may have crowded stops
        Algorithm: Minimize total fare, consider more stops for cheaper routes
        """
        start_stops = self._find_nearest_stops(start_lat, start_lon, 2)
        end_stops = self._find_nearest_stops(end_lat, end_lon, 2)
        
        if not start_stops or not end_stops:
            return {"error": "No nearby stops found"}
        
        start_stop = start_stops[0]
        end_stop = end_stops[0]
        
        # Budget route: take stops with lowest base_fare
        all_stops = self.db.query(Stop).all()
        route_stops = sorted(all_stops, key=lambda s: s.base_fare)[:4]
        
        if end_stop not in route_stops:
            route_stops.append(end_stop)
        
        stop_ids = [s.id for s in route_stops]
        distance = self._calculate_total_distance(route_stops)
        
        # Calculate total fare from all stops
        total_fare = sum(s.base_fare for s in route_stops)
        time_minutes = distance * 3.0  # Budget routes take longer
        comfort = self._calculate_comfort_score(stop_ids)
        
        return {
            "mode": "budget",
            "stops": [{"id": s.id, "name": s.name, "lat": s.latitude, "lon": s.longitude} for s in route_stops],
            "total_distance_km": round(distance, 2),
            "estimated_time_minutes": round(time_minutes, 1),
            "fare": round(total_fare, 2),
            "comfort_score": round(comfort, 2),
            "stop_sequence": stop_ids
        }
    
    def find_fastest_route(self, start_lat: float, start_lon: float, 
                          end_lat: float, end_lon: float) -> Dict:
        """
        FASTEST MODE: Minimize travel time, ignore comfort/budget
        Algorithm: Shortest straight-line path with fewest stops
        """
        start_stops = self._find_nearest_stops(start_lat, start_lon, 1)
        end_stops = self._find_nearest_stops(end_lat, end_lon, 1)
        
        if not start_stops or not end_stops:
            return {"error": "No nearby stops found"}
        
        start_stop = start_stops[0]
        end_stop = end_stops[0]
        
        # Fastest: Direct route with minimum stops
        all_stops = self.db.query(Stop).all()
        
        # Only take stops roughly between start and end
        min_lat = min(start_lat, end_lat) - 0.005
        max_lat = max(start_lat, end_lat) + 0.005
        min_lon = min(start_lon, end_lon) - 0.005
        max_lon = max(start_lon, end_lon) + 0.005
        
        candidate_stops = [
            s for s in all_stops 
            if min_lat <= s.latitude <= max_lat and min_lon <= s.longitude <= max_lon
        ]
        
        route_stops = candidate_stops[:2]  # Minimum stops
        if end_stop not in route_stops:
            route_stops.append(end_stop)
        
        stop_ids = [s.id for s in route_stops]
        distance = self._calculate_total_distance(route_stops)
        time_minutes = distance * 2.0  # Fast movement
        fare = self._calculate_fare(distance, "express", 0)
        comfort = self._calculate_comfort_score(stop_ids)
        
        return {
            "mode": "fastest",
            "stops": [{"id": s.id, "name": s.name, "lat": s.latitude, "lon": s.longitude} for s in route_stops],
            "total_distance_km": round(distance, 2),
            "estimated_time_minutes": round(time_minutes, 1),
            "fare": fare,
            "comfort_score": round(comfort, 2),
            "stop_sequence": stop_ids
        }
    
    def _calculate_total_distance(self, stops: List[Stop]) -> float:
        """Sum distances between consecutive stops"""
        total = 0.0
        for i in range(len(stops) - 1):
            total += self._haversine_distance(
                stops[i].latitude, stops[i].longitude,
                stops[i+1].latitude, stops[i+1].longitude
            )
        return total
    
    def find_all_routes(self, start_lat: float, start_lon: float, 
                       end_lat: float, end_lon: float) -> Dict:
        """Return all 3 route options for user to choose from"""
        return {
            "comfort": self.find_comfort_route(start_lat, start_lon, end_lat, end_lon),
            "budget": self.find_budget_route(start_lat, start_lon, end_lat, end_lon),
            "fastest": self.find_fastest_route(start_lat, start_lon, end_lat, end_lon),
        }