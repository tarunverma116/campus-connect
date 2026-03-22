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
