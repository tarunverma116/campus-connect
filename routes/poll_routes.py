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
