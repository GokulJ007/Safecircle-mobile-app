import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field
from app.models.journey import JourneyStatus
from app.schemas.location import LocationResponse

class JourneyStart(BaseModel):
    destination_name: str = Field(..., min_length=1, description="Name of the destination")
    destination_latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude of the destination")
    destination_longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude of the destination")
    eta: datetime = Field(..., description="Estimated Time of Arrival")

class JourneyResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    destination_name: str
    destination_latitude: float
    destination_longitude: float
    eta: datetime
    status: JourneyStatus
    started_at: datetime
    ended_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True

class JourneyDetailResponse(JourneyResponse):
    locations: List[LocationResponse] = []
