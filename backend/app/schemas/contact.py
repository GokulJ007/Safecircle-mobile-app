import uuid
from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field

class ContactCreate(BaseModel):
    contact_name: str = Field(..., min_length=1, description="Name of the trusted contact")
    contact_phone: str = Field(..., min_length=1, description="Phone number of the trusted contact")
    relationship: str = Field(..., min_length=1, description="Relationship to the user (e.g. Spouse, Parent, Friend)")

class ContactUpdate(BaseModel):
    contact_name: Optional[str] = Field(None, min_length=1)
    contact_phone: Optional[str] = Field(None, min_length=1)
    relationship: Optional[str] = Field(None, min_length=1)

class ContactResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    contact_name: str
    contact_phone: str
    relationship: str
    created_at: datetime

    class Config:
        from_attributes = True
