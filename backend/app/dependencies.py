from typing import Generator, Optional
from fastapi import Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import SessionLocal
from app.core.exceptions import CredentialsException
from app.models.user import User

# HTTPBearer allows pasting the token directly in Swagger UI
security_scheme = HTTPBearer(auto_error=False)

def get_db() -> Generator[Session, None, None]:
    """Dependency to retrieve database session per request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def get_current_user(
    db: Session = Depends(get_db),
    token_credentials: Optional[HTTPAuthorizationCredentials] = Depends(security_scheme)
) -> User:
    """Dependency to decode JWT token and fetch the currently authenticated user."""
    if token_credentials is None:
        raise CredentialsException("Not authenticated")
        
    token = token_credentials.credentials
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: str = payload.get("sub")
        if user_id is None:
            raise CredentialsException()
    except JWTError:
        raise CredentialsException()
    
    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise CredentialsException("User not found")
    return user
