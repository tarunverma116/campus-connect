import os
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from database import get_db
import models, schemas
from auth import hash_password, verify_password, create_access_token, get_current_user
from utils.email_verification import generate_otp, get_otp_expiry, send_verification_email

router = APIRouter()

@router.post("/signup")
def signup(req: schemas.SignupRequest, db: Session = Depends(get_db)):
    if db.query(models.User).filter(models.User.email == req.email).first():
        raise HTTPException(400, "Email already registered")
    otp = generate_otp()
    user = models.User(name=req.name, email=req.email, password_hash=hash_password(req.password),
                       otp_code=otp, otp_expires_at=get_otp_expiry(), is_verified=False)
    db.add(user); db.commit()
    send_verification_email(req.email, otp, req.name)
    return {"message": "Account created! Check your email for the OTP.", "email": req.email}

@router.post("/verify-otp", response_model=schemas.TokenResponse)
def verify_otp(req: schemas.OTPVerifyRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == req.email).first()
    if not user: raise HTTPException(404, "User not found")
    if user.is_verified: raise HTTPException(400, "Already verified")
    if user.otp_code != req.otp: raise HTTPException(400, "Invalid OTP")
    if user.otp_expires_at and datetime.utcnow() > user.otp_expires_at:
        raise HTTPException(400, "OTP expired. Request a new one.")
    user.is_verified = True; user.otp_code = None; user.otp_expires_at = None
    db.commit(); db.refresh(user)
    return {"access_token": create_access_token({"sub": str(user.id)}), "token_type": "bearer", "user": user}

@router.post("/resend-otp")
def resend_otp(email: str, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user: raise HTTPException(404, "User not found")
    if user.is_verified: raise HTTPException(400, "Already verified")
    otp = generate_otp()
    user.otp_code = otp; user.otp_expires_at = get_otp_expiry()
    db.commit(); send_verification_email(email, otp, user.name)
    return {"message": "New OTP sent"}

@router.post("/login", response_model=schemas.TokenResponse)
def login(req: schemas.LoginRequest, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == req.email).first()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(401, "Invalid email or password")
    if not user.is_verified:
        raise HTTPException(403, "Email not verified. Please verify first.")
    return {"access_token": create_access_token({"sub": str(user.id)}), "token_type": "bearer", "user": user}

@router.get("/me", response_model=schemas.UserResponse)
def get_me(current_user=Depends(get_current_user)):
    return current_user

@router.put("/profile", response_model=schemas.UserResponse)
def update_profile(req: schemas.UpdateProfileRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if req.name: current_user.name = req.name
    if req.bio is not None: current_user.bio = req.bio
    db.commit(); db.refresh(current_user); return current_user

@router.post("/upload-avatar", response_model=schemas.UserResponse)
async def upload_avatar(file: UploadFile = File(...), current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if file.content_type not in ["image/jpeg","image/png","image/webp","image/gif"]:
        raise HTTPException(400, "Only JPEG/PNG/WebP/GIF allowed")
    os.makedirs("uploads/avatars", exist_ok=True)
    ext = file.filename.split(".")[-1]
    path = f"uploads/avatars/avatar_{current_user.id}.{ext}"
    with open(path, "wb") as f: f.write(await file.read())
    current_user.profile_picture = f"/{path}"
    db.commit(); db.refresh(current_user); return current_user
