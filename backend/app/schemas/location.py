import uuid
from datetime import datetime
from pydantic import BaseModel, Field

class LocationCreate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude must be between -90 and 90 degrees")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude must be between -180 and 180 degrees")
    battery_percentage: float = Field(..., ge=0.0, le=100.0, description="Battery percentage must be between 0 and 100")

class LocationResponse(BaseModel):
    id: uuid.UUID
    journey_id: uuid.UUID
    latitude: float
    longitude: float
    battery_percentage: float
    recorded_at: datetime

    class Config:
        from_attributes = True
