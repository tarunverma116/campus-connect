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
