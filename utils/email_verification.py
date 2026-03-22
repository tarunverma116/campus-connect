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
