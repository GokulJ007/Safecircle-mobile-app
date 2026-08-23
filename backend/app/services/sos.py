import uuid
from sqlalchemy.orm import Session
from app.models.sos import SOSAlert, SOSStatus
from app.models.journey import Journey, JourneyStatus
from app.models.notification import Notification
from app.schemas.sos import SOSCreate
from app.core.exceptions import BadRequestException
from app.services.journey import get_journey_by_id_and_user

def create_sos_alert(db: Session, user_id: uuid.UUID, sos_data: SOSCreate) -> SOSAlert:
    """Create an SOS alert, update the journey status to SOS, and trigger a database notification."""
    journey = get_journey_by_id_and_user(db, sos_data.journey_id, user_id)
    if journey.status in (JourneyStatus.COMPLETED, JourneyStatus.CANCELLED):
        raise BadRequestException("Cannot trigger SOS on a completed or cancelled journey")
        
    # Set journey status to SOS
    journey.status = JourneyStatus.SOS
    
    # Instantiate SOS record
    db_sos = SOSAlert(
        user_id=user_id,
        journey_id=sos_data.journey_id,
        latitude=sos_data.latitude,
        longitude=sos_data.longitude,
        alert_status=SOSStatus.ACTIVE,
    )
    db.add(db_sos)
    
    # Create notification record
    db_notif = Notification(
        user_id=user_id,
        title="Emergency SOS Activated",
        message=f"SOS alert has been initiated for your journey to {journey.destination_name}."
    )
    db.add(db_notif)
    
    db.commit()
    db.refresh(db_sos)
    return db_sos
