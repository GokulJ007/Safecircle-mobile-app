import uuid
import enum
from datetime import datetime
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import String, Float, DateTime, ForeignKey, func, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base

if TYPE_CHECKING:
    from app.models.user import User
    from app.models.location import JourneyLocation
    from app.models.sos import SOSAlert

class JourneyStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    COMPLETED = "COMPLETED"
    CANCELLED = "CANCELLED"
    SOS = "SOS"

class Journey(Base):
    __tablename__ = "journeys"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    user_id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    destination_name: Mapped[str] = mapped_column(String(255), nullable=False)
    destination_latitude: Mapped[float] = mapped_column(Float, nullable=False)
    destination_longitude: Mapped[float] = mapped_column(Float, nullable=False)
    eta: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    status: Mapped[JourneyStatus] = mapped_column(
        Enum(JourneyStatus, name="journey_status"),
        default=JourneyStatus.ACTIVE,
        nullable=False,
    )
    started_at: Mapped[datetime] = mapped_column(
        DateTime, default=func.now(), nullable=False
    )
    ended_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, default=func.now(), nullable=False
    )

    # Relationships
    user: Mapped["User"] = relationship("User", back_populates="journeys")
    locations: Mapped[List["JourneyLocation"]] = relationship(
        "JourneyLocation", back_populates="journey", cascade="all, delete-orphan"
    )
    sos_alerts: Mapped[List["SOSAlert"]] = relationship(
        "SOSAlert", back_populates="journey", cascade="all, delete-orphan"
    )
