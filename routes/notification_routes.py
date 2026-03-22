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
