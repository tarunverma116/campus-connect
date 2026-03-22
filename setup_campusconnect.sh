#!/bin/bash
# CampusConnect — Full Auto-Setup Script for Mac
# Run this from ~/Downloads/files/

set -e
BASE="$HOME/Downloads/files"
cd "$BASE"

echo "📁 Creating folder structure..."
mkdir -p routes utils frontend/src/{components,pages,services,context}

echo "📝 Writing all backend Python files..."

# ── database.py ──────────────────────────────────────────────────────────────
cat > database.py << 'EOF'
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:password@localhost:5432/campusconnect")
engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
EOF

# ── models.py ─────────────────────────────────────────────────────────────────
cat > models.py << 'EOF'
from sqlalchemy import Column, Integer, String, Boolean, Text, ForeignKey, DateTime, func
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=False)
    password_hash = Column(String(255), nullable=False)
    profile_picture = Column(String(500), nullable=True)
    bio = Column(String(300), nullable=True)
    is_verified = Column(Boolean, default=False)
    otp_code = Column(String(10), nullable=True)
    otp_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=func.now())
    posts = relationship("Post", back_populates="author", cascade="all, delete-orphan")
    likes = relationship("Like", back_populates="user", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="author", cascade="all, delete-orphan")
    poll_votes = relationship("PollVote", back_populates="user", cascade="all, delete-orphan")
    notifications = relationship("Notification", foreign_keys="Notification.recipient_id", back_populates="recipient", cascade="all, delete-orphan")
    reports = relationship("Report", back_populates="reporter", cascade="all, delete-orphan")

class Post(Base):
    __tablename__ = "posts"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    image_url = Column(String(500), nullable=True)
    is_anonymous = Column(Boolean, default=False)
    is_reported = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    author = relationship("User", back_populates="posts")
    likes = relationship("Like", back_populates="post", cascade="all, delete-orphan")
    comments = relationship("Comment", back_populates="post", cascade="all, delete-orphan")
    reports = relationship("Report", back_populates="post", cascade="all, delete-orphan")

class Like(Base):
    __tablename__ = "likes"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    created_at = Column(DateTime, default=func.now())
    user = relationship("User", back_populates="likes")
    post = relationship("Post", back_populates="likes")

class Comment(Base):
    __tablename__ = "comments"
    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    content = Column(Text, nullable=False)
    created_at = Column(DateTime, default=func.now())
    post = relationship("Post", back_populates="comments")
    author = relationship("User", back_populates="comments")

class Poll(Base):
    __tablename__ = "polls"
    id = Column(Integer, primary_key=True, index=True)
    question = Column(String(500), nullable=False)
    created_by = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=func.now())
    creator = relationship("User")
    options = relationship("PollOption", back_populates="poll", cascade="all, delete-orphan")
    votes = relationship("PollVote", back_populates="poll", cascade="all, delete-orphan")

class PollOption(Base):
    __tablename__ = "poll_options"
    id = Column(Integer, primary_key=True, index=True)
    poll_id = Column(Integer, ForeignKey("polls.id"), nullable=False)
    option_text = Column(String(300), nullable=False)
    votes_count = Column(Integer, default=0)
    poll = relationship("Poll", back_populates="options")
    votes = relationship("PollVote", back_populates="option", cascade="all, delete-orphan")

class PollVote(Base):
    __tablename__ = "poll_votes"
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    poll_id = Column(Integer, ForeignKey("polls.id"), nullable=False)
    option_id = Column(Integer, ForeignKey("poll_options.id"), nullable=False)
    created_at = Column(DateTime, default=func.now())
    user = relationship("User", back_populates="poll_votes")
    poll = relationship("Poll", back_populates="votes")
    option = relationship("PollOption", back_populates="votes")

class Notification(Base):
    __tablename__ = "notifications"
    id = Column(Integer, primary_key=True, index=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    type = Column(String(50), nullable=False)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=True)
    message = Column(String(300), nullable=False)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())
    recipient = relationship("User", foreign_keys=[recipient_id], back_populates="notifications")
    sender = relationship("User", foreign_keys=[sender_id])
    post = relationship("Post")

class Report(Base):
    __tablename__ = "reports"
    id = Column(Integer, primary_key=True, index=True)
    post_id = Column(Integer, ForeignKey("posts.id"), nullable=False)
    reporter_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    reason = Column(String(300), nullable=True)
    created_at = Column(DateTime, default=func.now())
    post = relationship("Post", back_populates="reports")
    reporter = relationship("User", back_populates="reports")
EOF

# ── schemas.py ────────────────────────────────────────────────────────────────
cat > schemas.py << 'EOF'
from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional, List
from datetime import datetime

class SignupRequest(BaseModel):
    name: str
    email: EmailStr
    password: str
    @field_validator("email")
    @classmethod
    def validate_university_email(cls, v):
        if not v.endswith("@gla.ac.in"):
            raise ValueError("Only @gla.ac.in email addresses are allowed")
        return v
    @field_validator("password")
    @classmethod
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError("Password must be at least 6 characters")
        return v

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class OTPVerifyRequest(BaseModel):
    email: EmailStr
    otp: str

class UserResponse(BaseModel):
    id: int
    name: str
    email: str
    profile_picture: Optional[str] = None
    bio: Optional[str] = None
    is_verified: bool
    created_at: datetime
    class Config:
        from_attributes = True

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse

class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None

class CreatePostRequest(BaseModel):
    content: str
    image_url: Optional[str] = None
    is_anonymous: bool = False

class LikeRequest(BaseModel):
    post_id: int

class ReportRequest(BaseModel):
    post_id: int
    reason: Optional[str] = None

class AddCommentRequest(BaseModel):
    post_id: int
    content: str

class CreatePollRequest(BaseModel):
    question: str
    options: List[str]
    @field_validator("options")
    @classmethod
    def validate_options(cls, v):
        if len(v) < 2:
            raise ValueError("Need at least 2 options")
        if len(v) > 6:
            raise ValueError("Max 6 options allowed")
        return v

class VoteRequest(BaseModel):
    poll_id: int
    option_id: int
EOF

# ── auth.py ───────────────────────────────────────────────────────────────────
cat > auth.py << 'EOF'
from datetime import datetime, timedelta
from typing import Optional
import os
from jose import JWTError, jwt
from passlib.context import CryptContext
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session
from database import get_db
import models

SECRET_KEY = os.getenv("JWT_SECRET_KEY", "dev-secret-key-change-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 7

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
security = HTTPBearer()

def hash_password(plain: str) -> str:
    return pwd_context.hash(plain)

def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)

def create_access_token(data: dict) -> str:
    to_encode = data.copy()
    to_encode["exp"] = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)

def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: Session = Depends(get_db)
) -> models.User:
    try:
        payload = jwt.decode(credentials.credentials, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid or expired token")
    user = db.query(models.User).filter(models.User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    if not user.is_verified:
        raise HTTPException(status_code=403, detail="Email not verified")
    return user
EOF

# ── utils/__init__.py ─────────────────────────────────────────────────────────
touch utils/__init__.py

# ── utils/email_verification.py ───────────────────────────────────────────────
cat > utils/email_verification.py << 'EOF'
import random, string, smtplib, os
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

def generate_otp(length=6):
    return ''.join(random.choices(string.digits, k=length))

def get_otp_expiry(minutes=10):
    return datetime.utcnow() + timedelta(minutes=minutes)

def send_verification_email(to_email, otp, user_name):
    smtp_host = os.getenv("SMTP_HOST", "")
    smtp_user = os.getenv("SMTP_USER", "")
    smtp_password = os.getenv("SMTP_PASSWORD", "")
    smtp_port = int(os.getenv("SMTP_PORT", "587"))
    if not smtp_host or not smtp_user:
        print(f"\n{'='*50}")
        print(f"📧 DEV MODE — Email Verification OTP")
        print(f"   To:   {to_email}")
        print(f"   Name: {user_name}")
        print(f"   OTP:  {otp}")
        print(f"{'='*50}\n")
        return True
    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = "CampusConnect — Verify Your Email"
        msg["From"] = smtp_user
        msg["To"] = to_email
        msg.attach(MIMEText(f"Hi {user_name}, your OTP is: {otp} (valid 10 min)", "plain"))
        with smtplib.SMTP(smtp_host, smtp_port) as s:
            s.starttls()
            s.login(smtp_user, smtp_password)
            s.sendmail(smtp_user, to_email, msg.as_string())
        return True
    except Exception as e:
        print(f"Email failed: {e}\nFallback OTP for {to_email}: {otp}")
        return False
EOF

# ── utils/profanity_filter.py ─────────────────────────────────────────────────
cat > utils/profanity_filter.py << 'EOF'
BLOCKED_WORDS = {"fuck","shit","bitch","asshole","bastard","cunt","dick","pussy","slut","whore","nigger","nigga","faggot","retard","kys"}
def contains_profanity(text):
    lower = text.lower()
    for word in lower.split():
        if word.strip(".,!?;:'\"()[]{}") in BLOCKED_WORDS:
            return True
    return "kill yourself" in lower
EOF

# ── routes/__init__.py ────────────────────────────────────────────────────────
touch routes/__init__.py

# ── routes/auth_routes.py ─────────────────────────────────────────────────────
cat > routes/auth_routes.py << 'EOF'
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
EOF

# ── routes/post_routes.py ─────────────────────────────────────────────────────
cat > routes/post_routes.py << 'EOF'
import os, time
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from database import get_db
import models, schemas
from auth import get_current_user
from utils.profanity_filter import contains_profanity

router = APIRouter()

def build_post(post, current_user, db):
    likes = db.query(func.count(models.Like.id)).filter(models.Like.post_id == post.id).scalar()
    comments = db.query(func.count(models.Comment.id)).filter(models.Comment.post_id == post.id).scalar()
    liked = bool(db.query(models.Like).filter(models.Like.post_id == post.id, models.Like.user_id == current_user.id).first()) if current_user else False
    author = None if post.is_anonymous else ({"id": post.author.id, "name": post.author.name, "profile_picture": post.author.profile_picture} if post.author else None)
    return {"id": post.id, "content": post.content, "image_url": post.image_url, "is_anonymous": post.is_anonymous,
            "created_at": post.created_at, "author": author, "likes_count": likes, "comments_count": comments, "is_liked_by_me": liked}

@router.post("/create")
async def create_post(content: str = Form(...), is_anonymous: bool = Form(False),
                       image: Optional[UploadFile] = File(None),
                       current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if not content.strip(): raise HTTPException(400, "Content cannot be empty")
    if contains_profanity(content): raise HTTPException(400, "Post contains inappropriate language")
    image_url = None
    if image and image.filename:
        if image.content_type not in ["image/jpeg","image/png","image/webp","image/gif"]:
            raise HTTPException(400, "Only image files allowed")
        os.makedirs("uploads/posts", exist_ok=True)
        ext = image.filename.split(".")[-1]
        fname = f"uploads/posts/post_{current_user.id}_{int(time.time())}.{ext}"
        with open(fname, "wb") as f: f.write(await image.read())
        image_url = f"/{fname}"
    post = models.Post(user_id=current_user.id, content=content.strip(), image_url=image_url, is_anonymous=is_anonymous)
    db.add(post); db.commit(); db.refresh(post)
    return {"message": "Post created", "post_id": post.id}

@router.get("/feed")
def get_feed(page: int = Query(1, ge=1), limit: int = Query(10, ge=1, le=50),
             current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    posts = db.query(models.Post).order_by(desc(models.Post.created_at)).offset((page-1)*limit).limit(limit).all()
    return [build_post(p, current_user, db) for p in posts]

@router.get("/trending")
def get_trending(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    from datetime import datetime, timedelta
    since = datetime.utcnow() - timedelta(days=7)
    lc = db.query(models.Like.post_id, func.count(models.Like.id).label("lc")).filter(models.Like.created_at >= since).group_by(models.Like.post_id).subquery()
    posts = db.query(models.Post).outerjoin(lc, models.Post.id == lc.c.post_id).filter(models.Post.created_at >= since).order_by(desc(func.coalesce(lc.c.lc, 0))).limit(10).all()
    return [build_post(p, current_user, db) for p in posts]

@router.get("/user/{user_id}")
def get_user_posts(user_id: int, page: int = Query(1), current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    posts = db.query(models.Post).filter(models.Post.user_id == user_id).order_by(desc(models.Post.created_at)).offset((page-1)*10).limit(10).all()
    return [build_post(p, current_user, db) for p in posts]

@router.post("/like")
def like_post(req: schemas.LikeRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    post = db.query(models.Post).filter(models.Post.id == req.post_id).first()
    if not post: raise HTTPException(404, "Post not found")
    if db.query(models.Like).filter(models.Like.user_id == current_user.id, models.Like.post_id == req.post_id).first():
        raise HTTPException(400, "Already liked")
    db.add(models.Like(user_id=current_user.id, post_id=req.post_id))
    if post.user_id != current_user.id:
        db.add(models.Notification(recipient_id=post.user_id, sender_id=current_user.id, type="like",
               post_id=post.id, message=f"{current_user.name} liked your post"))
    db.commit(); return {"message": "Liked"}

@router.delete("/unlike")
def unlike_post(req: schemas.LikeRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    like = db.query(models.Like).filter(models.Like.user_id == current_user.id, models.Like.post_id == req.post_id).first()
    if not like: raise HTTPException(404, "Like not found")
    db.delete(like); db.commit(); return {"message": "Unliked"}

@router.post("/report")
def report_post(req: schemas.ReportRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    post = db.query(models.Post).filter(models.Post.id == req.post_id).first()
    if not post: raise HTTPException(404, "Post not found")
    if db.query(models.Report).filter(models.Report.post_id == req.post_id, models.Report.reporter_id == current_user.id).first():
        raise HTTPException(400, "Already reported")
    db.add(models.Report(post_id=req.post_id, reporter_id=current_user.id, reason=req.reason))
    count = db.query(func.count(models.Report.id)).filter(models.Report.post_id == req.post_id).scalar()
    if count >= 2: post.is_reported = True
    db.commit(); return {"message": "Reported"}

@router.delete("/{post_id}")
def delete_post(post_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    post = db.query(models.Post).filter(models.Post.id == post_id).first()
    if not post: raise HTTPException(404, "Not found")
    if post.user_id != current_user.id: raise HTTPException(403, "Not your post")
    db.delete(post); db.commit(); return {"message": "Deleted"}
EOF

# ── routes/comment_routes.py ──────────────────────────────────────────────────
cat > routes/comment_routes.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
import models, schemas
from auth import get_current_user
from utils.profanity_filter import contains_profanity

router = APIRouter()

@router.post("/add")
def add_comment(req: schemas.AddCommentRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    post = db.query(models.Post).filter(models.Post.id == req.post_id).first()
    if not post: raise HTTPException(404, "Post not found")
    if contains_profanity(req.content): raise HTTPException(400, "Inappropriate language")
    c = models.Comment(post_id=req.post_id, user_id=current_user.id, content=req.content.strip())
    db.add(c)
    if post.user_id != current_user.id:
        db.add(models.Notification(recipient_id=post.user_id, sender_id=current_user.id, type="comment",
               post_id=post.id, message=f"{current_user.name} commented on your post"))
    db.commit(); db.refresh(c)
    return {"id": c.id, "post_id": c.post_id, "content": c.content, "created_at": c.created_at,
            "author": {"id": current_user.id, "name": current_user.name, "profile_picture": current_user.profile_picture}}

@router.get("/{post_id}")
def get_comments(post_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    comments = db.query(models.Comment).filter(models.Comment.post_id == post_id).order_by(models.Comment.created_at).all()
    return [{"id": c.id, "post_id": c.post_id, "content": c.content, "created_at": c.created_at,
             "author": {"id": c.author.id, "name": c.author.name, "profile_picture": c.author.profile_picture}} for c in comments]

@router.delete("/{comment_id}")
def delete_comment(comment_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    c = db.query(models.Comment).filter(models.Comment.id == comment_id).first()
    if not c: raise HTTPException(404, "Not found")
    if c.user_id != current_user.id: raise HTTPException(403, "Not your comment")
    db.delete(c); db.commit(); return {"message": "Deleted"}
EOF

# ── routes/poll_routes.py ─────────────────────────────────────────────────────
cat > routes/poll_routes.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import desc
from database import get_db
import models, schemas
from auth import get_current_user
from utils.profanity_filter import contains_profanity

router = APIRouter()

def build_poll(poll, current_user, db):
    vote = db.query(models.PollVote).filter(models.PollVote.poll_id == poll.id, models.PollVote.user_id == current_user.id).first()
    return {"id": poll.id, "question": poll.question, "created_at": poll.created_at,
            "options": [{"id": o.id, "option_text": o.option_text, "votes_count": o.votes_count} for o in poll.options],
            "total_votes": sum(o.votes_count for o in poll.options),
            "my_vote_option_id": vote.option_id if vote else None}

@router.post("/create")
def create_poll(req: schemas.CreatePollRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    if contains_profanity(req.question): raise HTTPException(400, "Inappropriate language in question")
    poll = models.Poll(question=req.question, created_by=current_user.id)
    db.add(poll); db.flush()
    for opt in req.options:
        if contains_profanity(opt): db.rollback(); raise HTTPException(400, f"Inappropriate language in option: {opt}")
        db.add(models.PollOption(poll_id=poll.id, option_text=opt.strip()))
    db.commit(); return {"message": "Poll created", "poll_id": poll.id}

@router.post("/vote")
def vote(req: schemas.VoteRequest, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    poll = db.query(models.Poll).filter(models.Poll.id == req.poll_id).first()
    if not poll: raise HTTPException(404, "Poll not found")
    opt = db.query(models.PollOption).filter(models.PollOption.id == req.option_id, models.PollOption.poll_id == req.poll_id).first()
    if not opt: raise HTTPException(404, "Option not found")
    if db.query(models.PollVote).filter(models.PollVote.user_id == current_user.id, models.PollVote.poll_id == req.poll_id).first():
        raise HTTPException(400, "Already voted")
    db.add(models.PollVote(user_id=current_user.id, poll_id=req.poll_id, option_id=req.option_id))
    opt.votes_count += 1; db.commit(); return {"message": "Vote recorded"}

@router.get("/all")
def get_all(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    polls = db.query(models.Poll).order_by(desc(models.Poll.created_at)).all()
    return [build_poll(p, current_user, db) for p in polls]

@router.get("/{poll_id}")
def get_poll(poll_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    poll = db.query(models.Poll).filter(models.Poll.id == poll_id).first()
    if not poll: raise HTTPException(404, "Poll not found")
    return build_poll(poll, current_user, db)
EOF

# ── routes/notification_routes.py ────────────────────────────────────────────
cat > routes/notification_routes.py << 'EOF'
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from database import get_db
import models
from auth import get_current_user

router = APIRouter()

@router.get("/")
def get_notifications(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    notifs = db.query(models.Notification).filter(models.Notification.recipient_id == current_user.id).order_by(desc(models.Notification.created_at)).limit(50).all()
    return [{"id": n.id, "type": n.type, "message": n.message, "is_read": n.is_read, "post_id": n.post_id,
             "created_at": n.created_at, "sender": {"id": n.sender.id, "name": n.sender.name, "profile_picture": n.sender.profile_picture} if n.sender else None} for n in notifs]

@router.get("/unread-count")
def unread_count(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    count = db.query(func.count(models.Notification.id)).filter(models.Notification.recipient_id == current_user.id, models.Notification.is_read == False).scalar()
    return {"unread_count": count}

@router.put("/read-all")
def mark_all_read(current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    db.query(models.Notification).filter(models.Notification.recipient_id == current_user.id, models.Notification.is_read == False).update({"is_read": True})
    db.commit(); return {"message": "All read"}

@router.put("/{notification_id}/read")
def mark_read(notification_id: int, current_user=Depends(get_current_user), db: Session = Depends(get_db)):
    n = db.query(models.Notification).filter(models.Notification.id == notification_id, models.Notification.recipient_id == current_user.id).first()
    if not n: raise HTTPException(404, "Not found")
    n.is_read = True; db.commit(); return {"message": "Marked read"}
EOF

# ── main.py ───────────────────────────────────────────────────────────────────
cat > main.py << 'EOF'
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from database import engine, Base
from routes import auth_routes, post_routes, comment_routes, poll_routes, notification_routes

Base.metadata.create_all(bind=engine)
app = FastAPI(title="CampusConnect API")
app.add_middleware(CORSMiddleware, allow_origins=["http://localhost:5173","http://127.0.0.1:5173"],
                   allow_credentials=True, allow_methods=["*"], allow_headers=["*"])
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.include_router(auth_routes.router, prefix="/auth", tags=["Auth"])
app.include_router(post_routes.router, prefix="/posts", tags=["Posts"])
app.include_router(comment_routes.router, prefix="/comments", tags=["Comments"])
app.include_router(poll_routes.router, prefix="/poll", tags=["Polls"])
app.include_router(notification_routes.router, prefix="/notifications", tags=["Notifications"])

@app.get("/")
def root(): return {"message": "CampusConnect API running 🎓"}
EOF

# ── requirements.txt ──────────────────────────────────────────────────────────
cat > requirements.txt << 'EOF'
fastapi==0.111.0
uvicorn[standard]==0.29.0
sqlalchemy==2.0.30
psycopg2-binary==2.9.9
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.9
python-dotenv==1.0.1
pydantic[email]==2.7.1
EOF

# ── .env ──────────────────────────────────────────────────────────────────────
cat > .env << 'EOF'
DATABASE_URL=postgresql://postgres:password@localhost:5432/campusconnect
JWT_SECRET_KEY=super-secret-dev-key-change-in-production
SMTP_HOST=
SMTP_USER=
SMTP_PASSWORD=
FROM_EMAIL=
EOF

echo ""
echo "✅ All backend files created!"
echo ""
echo "📦 Installing Python packages..."
pip install -r requirements.txt

echo ""
echo "🗄️  Setting up PostgreSQL..."
# Try to create DB (may already exist — that's fine)
createdb campusconnect 2>/dev/null && echo "✅ Database created" || echo "ℹ️  Database may already exist — continuing"

echo ""
echo "🚀 Starting backend..."
uvicorn main:app --reload --port 8000
