from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from jose import JWTError, jwt

from app.database import get_db
from app.models.user import User
from app.schemas.auth import (
    UserCreate,
    UserLogin,
    UserOut,
    UserUpdate,
    Token,
    TokenRefresh,
)
from app.security.auth import (
    hash_password,
    verify_password,
    create_access_token,
    create_refresh_token,
    get_current_user,
)
from app.config import get_settings

router = APIRouter(prefix="/auth", tags=["Authentication"])
settings = get_settings()


@router.post("/register", response_model=Token, status_code=status.HTTP_201_CREATED)
def register(user_in: UserCreate, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == user_in.email.lower()).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="A user with this email already exists",
        )

    allowed_roles = ["citizen", "collector", "authority", "admin"]
    role = user_in.role if user_in.role in allowed_roles else "citizen"

    user = User(
        name=user_in.name.strip(),
        email=user_in.email.lower().strip(),
        hashed_password=hash_password(user_in.password),
        role=role,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token_payload = {"sub": str(user.id), "role": user.role}
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    return Token(
        access_token=access_token,
        token_type="bearer",
        refresh_token=refresh_token,
    )


@router.post("/login", response_model=Token)
def login(credentials: UserLogin, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == credentials.email.lower().strip()).first()
    if not user or not verify_password(credentials.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User account is deactivated",
        )

    token_payload = {"sub": str(user.id), "role": user.role}
    access_token = create_access_token(token_payload)
    refresh_token = create_refresh_token(token_payload)

    return Token(
        access_token=access_token,
        token_type="bearer",
        refresh_token=refresh_token,
    )


@router.post("/refresh", response_model=Token)
def refresh_token(token_in: TokenRefresh, db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(
            token_in.refresh_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        token_type = payload.get("type")
        user_id = payload.get("sub")
        if token_type != "refresh" or not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
            )
        user = db.query(User).filter(User.id == int(user_id)).first()
        if not user or not user.is_active:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive",
            )

        new_payload = {"sub": str(user.id), "role": user.role}
        new_access_token = create_access_token(new_payload)

        return Token(
            access_token=new_access_token,
            token_type="bearer",
            refresh_token=token_in.refresh_token,
        )
    except (JWTError, ValueError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired refresh token",
        )


@router.get("/me", response_model=UserOut)
def get_current_user_profile(current_user: User = Depends(get_current_user)):
    return current_user


@router.put("/me", response_model=UserOut)
def update_profile(
    update_data: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if update_data.name is not None and update_data.name.strip():
        current_user.name = update_data.name.strip()
    db.commit()
    db.refresh(current_user)
    return current_user
