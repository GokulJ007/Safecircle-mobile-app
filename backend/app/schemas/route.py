from pydantic import BaseModel, Field

class RouteRequest(BaseModel):
    origin_latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude of the origin")
    origin_longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude of the origin")
    destination_latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude of the destination")
    destination_longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude of the destination")

class RouteResponse(BaseModel):
    distance_meters: int
    duration_seconds: int
    duration_text: str
    distance_text: str
    polyline: str
