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
