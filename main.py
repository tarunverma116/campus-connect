from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from database import engine, Base
from routes import auth_routes, post_routes, comment_routes, poll_routes, notification_routes

Base.metadata.create_all(bind=engine)
app = FastAPI(title="CampusConnect API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.include_router(auth_routes.router, prefix="/auth", tags=["Auth"])
app.include_router(post_routes.router, prefix="/posts", tags=["Posts"])
app.include_router(comment_routes.router, prefix="/comments", tags=["Comments"])
app.include_router(post_routes.router, prefix="/poll", tags=["Polls"])
app.include_router(notification_routes.router, prefix="/notifications", tags=["Notifications"])

@app.get("/")
def root(): return {"message": "CampusConnect API running 🎓"}
