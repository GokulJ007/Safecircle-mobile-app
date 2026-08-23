from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user
from app.schemas.sos import SOSCreate, SOSResponse
from app.models.user import User
from app.services.sos import create_sos_alert

router = APIRouter(prefix="/sos", tags=["SOS Emergency Alerts"])

@router.post("", response_model=SOSResponse, status_code=status.HTTP_201_CREATED)
def trigger_sos(
    sos_data: SOSCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Trigger an emergency SOS alert for an active journey, marking the journey status as SOS."""
    return create_sos_alert(db, current_user.id, sos_data)
