import uuid
from datetime import datetime
from pydantic import BaseModel, Field
from app.models.sos import SOSStatus

class SOSCreate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Current latitude of the user triggering SOS")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Current longitude of the user triggering SOS")
    journey_id: uuid.UUID = Field(..., description="The ID of the journey associated with this SOS alert")

class SOSResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    journey_id: uuid.UUID
    latitude: float
    longitude: float
    alert_status: SOSStatus
    created_at: datetime

    class Config:
        from_attributes = True
