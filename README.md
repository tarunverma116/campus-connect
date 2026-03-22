# 🎓 CampusConnect

A hyper-local social media platform exclusively for university students — like a private Instagram + Reddit for your campus.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🔐 Auth | JWT-based login, university email restriction (@gla.ac.in), OTP email verification |
| 📝 Posts | Create posts with images, anonymous posting, like/unlike, delete own posts |
| 💬 Comments | Threaded comments on posts |
| 📊 Polls | Create polls (2–6 options), one vote per user, live results |
| 🔥 Trending | Posts ranked by likes in the last 7 days |
| 🔔 Notifications | Real-time-style notifications for likes and comments |
| 🛡️ Moderation | Profanity filter, report posts, auto-flag at 3+ reports |
| 👤 Profile | Avatar upload, bio, edit profile, view own posts + stats |
| 🌙 Dark mode | Beautiful dark UI with Tailwind CSS |

---

## 🏗️ Tech Stack

- **Frontend**: React 18 + Vite + Tailwind CSS
- **Backend**: FastAPI (Python)
- **Database**: PostgreSQL + SQLAlchemy ORM
- **Auth**: JWT (python-jose) + bcrypt password hashing
- **Email**: SMTP (dev mode prints OTP to console)
- **Images**: Local filesystem (`/uploads` directory)

---

## 📁 Project Structure

```
campusconnect/
├── backend/
│   ├── main.py                  # FastAPI app entry point
│   ├── database.py              # SQLAlchemy engine & session
│   ├── models.py                # Database models
│   ├── schemas.py               # Pydantic schemas
│   ├── auth.py                  # JWT + bcrypt utilities
│   ├── requirements.txt
│   ├── .env.example
│   ├── routes/
│   │   ├── auth_routes.py
│   │   ├── post_routes.py
│   │   ├── comment_routes.py
│   │   ├── poll_routes.py
│   │   └── notification_routes.py
│   └── utils/
│       ├── email_verification.py
│       └── profanity_filter.py
└── frontend/
    ├── index.html
    ├── vite.config.js
    ├── tailwind.config.js
    ├── package.json
    ├── .env.example
    └── src/
        ├── main.jsx
        ├── App.jsx
        ├── index.css
        ├── context/
        │   └── AuthContext.jsx
        ├── services/
        │   └── api.js
        ├── components/
        │   ├── Navbar.jsx
        │   ├── Layout.jsx
        │   ├── PostCard.jsx
        │   ├── CreatePostModal.jsx
        │   ├── PollCard.jsx
        │   └── CreatePollModal.jsx
        └── pages/
            ├── Login.jsx
            ├── Signup.jsx
            ├── Verify.jsx
            ├── Feed.jsx
            ├── Trending.jsx
            ├── Polls.jsx
            ├── Notifications.jsx
            └── Profile.jsx
```

---

## 🚀 Setup Instructions

### Prerequisites

- Python 3.10+
- Node.js 18+
- PostgreSQL 14+

---

### 1. Database Setup

```bash
# Start PostgreSQL (Mac with Homebrew)
brew services start postgresql@14

# Or Ubuntu/Debian
sudo service postgresql start

# Create the database
psql -U postgres
```

Inside psql:
```sql
CREATE DATABASE campusconnect;
\q
```

---

### 2. Backend Setup

```bash
cd campusconnect/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate          # Mac/Linux
# OR: venv\Scripts\activate       # Windows

# Install dependencies
pip install -r requirements.txt

# Copy and configure environment variables
cp .env.example .env
```

Edit `.env` with your actual values:
```env
DATABASE_URL=postgresql://postgres:YOUR_PASSWORD@localhost:5432/campusconnect
JWT_SECRET_KEY=some-long-random-secret-string-change-this

# Leave SMTP blank to use dev mode (OTP prints to console)
SMTP_HOST=
SMTP_USER=
SMTP_PASSWORD=
FROM_EMAIL=
```

Start the backend:
```bash
uvicorn main:app --reload --port 8000
```

The API will be live at **http://localhost:8000**  
Interactive docs at **http://localhost:8000/docs**

---

### 3. Frontend Setup

```bash
cd campusconnect/frontend

# Install dependencies
npm install

# Copy environment file
cp .env.example .env
# .env should contain: VITE_API_URL=http://localhost:8000

# Start dev server
npm run dev
```

The app will be live at **http://localhost:5173**

---

## 📧 Email Verification (Dev Mode)

By default (no SMTP configured), OTPs are **printed directly to the backend console** — no email sending needed for local development.

Look for this output when a user signs up:
```
==================================================
📧 DEV MODE - Email Verification OTP
To: student@gla.ac.in
Name: Test Student
OTP: 482951
==================================================
```

To enable real email sending (e.g. Gmail):
1. Enable "App Passwords" in your Google account
2. Add these to your backend `.env`:
```env
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your@gmail.com
SMTP_PASSWORD=your-app-password
FROM_EMAIL=your@gmail.com
```

---

## 🌐 API Endpoints Reference

### Auth
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/signup` | Register (only @gla.ac.in emails) |
| POST | `/auth/login` | Login, returns JWT |
| POST | `/auth/verify-otp` | Verify email OTP |
| POST | `/auth/resend-otp?email=...` | Resend OTP |
| GET | `/auth/me` | Get current user |
| PUT | `/auth/profile` | Update name/bio |
| POST | `/auth/upload-avatar` | Upload profile picture |

### Posts
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/posts/create` | Create post (multipart/form-data) |
| GET | `/posts/feed?page=1` | Paginated feed |
| GET | `/posts/trending` | Top posts (last 7 days) |
| GET | `/posts/user/{id}` | Posts by user |
| POST | `/posts/like` | Like a post |
| DELETE | `/posts/unlike` | Unlike a post |
| POST | `/posts/report` | Report a post |
| DELETE | `/posts/{id}` | Delete own post |

### Comments
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/comments/add` | Add a comment |
| GET | `/comments/{post_id}` | Get comments for post |
| DELETE | `/comments/{id}` | Delete own comment |

### Polls
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/poll/create` | Create poll |
| POST | `/poll/vote` | Vote on poll |
| GET | `/poll/all` | All polls |
| GET | `/poll/{id}` | Single poll |

### Notifications
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications/` | All notifications |
| GET | `/notifications/unread-count` | Unread count |
| PUT | `/notifications/read-all` | Mark all read |
| PUT | `/notifications/{id}/read` | Mark one read |

---

## 🔧 Adding More Universities

To allow more university email domains, edit `backend/schemas.py`:

```python
@field_validator("email")
@classmethod
def validate_university_email(cls, v):
    allowed_domains = [
        "@gla.ac.in",
        "@iitd.ac.in",   # Add more here
        "@bits-pilani.ac.in",
    ]
    ...
```

---

## 🎨 Customisation

- **Brand colors**: Edit `frontend/tailwind.config.js` → `campus` color palette
- **App name**: Update `index.html` title and Navbar logo text
- **Blocked words**: Add to `backend/utils/profanity_filter.py` → `BLOCKED_WORDS` set
- **Post limit**: Change `limit` in `posts/feed` route (default 10)

---

## 🚢 Production Checklist

- [ ] Change `JWT_SECRET_KEY` to a cryptographically random 64-char string
- [ ] Set up real SMTP credentials
- [ ] Use a production PostgreSQL host (e.g. Supabase, Railway, Neon)
- [ ] Build frontend: `npm run build` and serve `dist/` with Nginx
- [ ] Run backend with: `uvicorn main:app --host 0.0.0.0 --port 8000 --workers 4`
- [ ] Add HTTPS (Nginx + Certbot)
- [ ] Set `CORS` origins to your actual domain in `main.py`
- [ ] Use Cloudinary or S3 for image storage in production

---

## 🐛 Troubleshooting

**"CORS error" on frontend?**  
→ Make sure backend is running on port 8000 and `VITE_API_URL` is set correctly.

**"relation does not exist" DB error?**  
→ Tables are auto-created on startup. Ensure PostgreSQL is running and `DATABASE_URL` is correct.

**OTP not received?**  
→ In dev mode, check backend console output. SMTP env vars are empty by design for local development.

**"Only university email addresses are allowed"?**  
→ You must use a `@gla.ac.in` email. Add your domain to the validator in `schemas.py`.

---

Made with ❤️ for university students everywhere.
