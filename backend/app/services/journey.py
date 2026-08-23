import uuid
from datetime import datetime
from typing import List
from sqlalchemy.orm import Session
from app.models.journey import Journey, JourneyStatus
from app.models.location import JourneyLocation
from app.schemas.journey import JourneyStart
from app.schemas.location import LocationCreate
from app.core.exceptions import NotFoundException, BadRequestException

def start_journey(db: Session, user_id: uuid.UUID, journey_data: JourneyStart) -> Journey:
    """Start a new journey for the user. Only one journey can be active at a time."""
    active_journey = db.query(Journey).filter(
        Journey.user_id == user_id,
        Journey.status == JourneyStatus.ACTIVE
    ).first()
    if active_journey:
        raise BadRequestException("User already has an active journey. End it before starting a new one.")
        
    db_journey = Journey(
        user_id=user_id,
        destination_name=journey_data.destination_name,
        destination_latitude=journey_data.destination_latitude,
        destination_longitude=journey_data.destination_longitude,
        eta=journey_data.eta,
        status=JourneyStatus.ACTIVE,
    )
    db.add(db_journey)
    db.commit()
    db.refresh(db_journey)
    return db_journey

def get_journey_by_id_and_user(db: Session, journey_id: uuid.UUID, user_id: uuid.UUID) -> Journey:
    """Retrieve a journey by ID, ensuring it belongs to the authenticated user."""
    journey = db.query(Journey).filter(
        Journey.id == journey_id,
        Journey.user_id == user_id
    ).first()
    if not journey:
        raise NotFoundException("Journey not found or access denied")
    return journey

def update_journey_location(
    db: Session, user_id: uuid.UUID, journey_id: uuid.UUID, location_data: LocationCreate
) -> JourneyLocation:
    """Record a new location history point for an active journey."""
    journey = get_journey_by_id_and_user(db, journey_id, user_id)
    if journey.status not in (JourneyStatus.ACTIVE, JourneyStatus.SOS):
         raise BadRequestException("Cannot update location for a completed or cancelled journey")
         
    db_location = JourneyLocation(
        journey_id=journey_id,
        latitude=location_data.latitude,
        longitude=location_data.longitude,
        battery_percentage=location_data.battery_percentage
    )
    db.add(db_location)
    db.commit()
    db.refresh(db_location)
    return db_location

def end_journey(db: Session, user_id: uuid.UUID, journey_id: uuid.UUID) -> Journey:
    """Complete an active journey, setting its status to COMPLETED and recording the end time."""
    journey = get_journey_by_id_and_user(db, journey_id, user_id)
    if journey.status in (JourneyStatus.COMPLETED, JourneyStatus.CANCELLED):
        raise BadRequestException("Journey has already ended")
        
    journey.status = JourneyStatus.COMPLETED
    journey.ended_at = datetime.now()
    db.commit()
    db.refresh(journey)
    return journey

def get_user_journey_history(db: Session, user_id: uuid.UUID) -> List[Journey]:
    """Retrieve a chronological list of all journeys started by the user."""
    return db.query(Journey).filter(Journey.user_id == user_id).order_by(Journey.created_at.desc()).all()
