import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user
from app.schemas.journey import JourneyStart, JourneyResponse, JourneyDetailResponse
from app.schemas.location import LocationCreate, LocationResponse
from app.models.user import User
from app.services.journey import (
    start_journey,
    update_journey_location,
    end_journey,
    get_user_journey_history,
    get_journey_by_id_and_user,
)

router = APIRouter(prefix="/journeys", tags=["Journeys"])

@router.post("/start", response_model=JourneyResponse, status_code=status.HTTP_201_CREATED)
def post_start_journey(
    journey_data: JourneyStart,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Start a new journey with a target destination and an estimated time of arrival (ETA)."""
    return start_journey(db, current_user.id, journey_data)

@router.put("/{journey_id}/location", response_model=LocationResponse)
def put_update_location(
    journey_id: uuid.UUID,
    location_data: LocationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Record current GPS coordinates and device battery percentage during an active journey."""
    return update_journey_location(db, current_user.id, journey_id, location_data)

@router.put("/{journey_id}/end", response_model=JourneyResponse)
def put_end_journey(
    journey_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Mark an active journey as successfully completed."""
    return end_journey(db, current_user.id, journey_id)

@router.get("/history", response_model=List[JourneyResponse])
def get_journey_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Retrieve all journey records (active and completed) for the authenticated user."""
    return get_user_journey_history(db, current_user.id)

@router.get("/{journey_id}", response_model=JourneyDetailResponse)
def get_journey(
    journey_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Retrieve details for a specific journey, including its complete historical breadcrumb trail."""
    return get_journey_by_id_and_user(db, journey_id, current_user.id)
