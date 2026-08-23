import uuid
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.contact import TrustedContact
from app.schemas.contact import ContactCreate, ContactUpdate
from app.core.exceptions import NotFoundException

def get_user_contacts(db: Session, user_id: uuid.UUID) -> List[TrustedContact]:
    """Retrieve all trusted contacts associated with a specific user."""
    return db.query(TrustedContact).filter(TrustedContact.user_id == user_id).all()

def get_contact_by_id_and_user(db: Session, contact_id: uuid.UUID, user_id: uuid.UUID) -> TrustedContact:
    """Retrieve a specific trusted contact only if they belong to the authenticated user."""
    contact = db.query(TrustedContact).filter(
        TrustedContact.id == contact_id,
        TrustedContact.user_id == user_id
    ).first()
    if not contact:
        raise NotFoundException("Trusted contact not found or access denied")
    return contact

def create_user_contact(db: Session, user_id: uuid.UUID, contact_data: ContactCreate) -> TrustedContact:
    """Create a trusted contact for a user."""
    db_contact = TrustedContact(
        user_id=user_id,
        contact_name=contact_data.contact_name,
        contact_phone=contact_data.contact_phone,
        relationship=contact_data.relationship,
    )
    db.add(db_contact)
    db.commit()
    db.refresh(db_contact)
    return db_contact

def update_user_contact(
    db: Session, user_id: uuid.UUID, contact_id: uuid.UUID, contact_data: ContactUpdate
) -> TrustedContact:
    """Update a specific trusted contact's information if owned by the user."""
    db_contact = get_contact_by_id_and_user(db, contact_id, user_id)
    
    update_dict = contact_data.model_dump(exclude_unset=True)
    for field, value in update_dict.items():
        setattr(db_contact, field, value)
        
    db.commit()
    db.refresh(db_contact)
    return db_contact

def delete_user_contact(db: Session, user_id: uuid.UUID, contact_id: uuid.UUID) -> None:
    """Delete a trusted contact from a user's contact book."""
    db_contact = get_contact_by_id_and_user(db, contact_id, user_id)
    db.delete(db_contact)
    db.commit()
