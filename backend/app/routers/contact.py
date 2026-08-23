import uuid
from typing import List
from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
from app.dependencies import get_db, get_current_user
from app.schemas.contact import ContactCreate, ContactUpdate, ContactResponse
from app.models.user import User
from app.services.contact import (
    get_user_contacts,
    create_user_contact,
    update_user_contact,
    delete_user_contact,
)

router = APIRouter(prefix="/contacts", tags=["Trusted Contacts"])

@router.get("", response_model=List[ContactResponse])
def read_contacts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Retrieve all trusted contacts for the authenticated user."""
    return get_user_contacts(db, current_user.id)

@router.post("", response_model=ContactResponse, status_code=status.HTTP_201_CREATED)
def create_contact(
    contact_data: ContactCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Add a new trusted contact to the user's circle."""
    return create_user_contact(db, current_user.id, contact_data)

@router.put("/{contact_id}", response_model=ContactResponse)
def update_contact(
    contact_id: uuid.UUID,
    contact_data: ContactUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Update details of a specific trusted contact belonging to the user."""
    return update_user_contact(db, current_user.id, contact_id, contact_data)

@router.delete("/{contact_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_contact(
    contact_id: uuid.UUID,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Remove a trusted contact from the user's circle."""
    delete_user_contact(db, current_user.id, contact_id)
