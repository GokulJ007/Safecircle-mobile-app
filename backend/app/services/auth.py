from typing import Optional
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.auth import UserRegister
from app.core.security import get_password_hash, verify_password
from app.core.exceptions import BadRequestException

def get_user_by_email(db: Session, email: str) -> Optional[User]:
    """Retrieve a user from the database by their email address."""
    return db.query(User).filter(User.email == email).first()

def register_user(db: Session, user_data: UserRegister) -> User:
    """Register a new user, checking for email uniqueness and hashing the password."""
    existing_user = get_user_by_email(db, user_data.email)
    if existing_user:
        raise BadRequestException("Email is already registered")
    
    hashed_password = get_password_hash(user_data.password)
    db_user = User(
        email=user_data.email,
        full_name=user_data.full_name,
        phone_number=user_data.phone_number,
        password_hash=hashed_password,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def authenticate_user(db: Session, email: str, password: str) -> Optional[User]:
    """Authenticate a user by email and password, returning the user if successful."""
    user = get_user_by_email(db, email)
    if not user:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
