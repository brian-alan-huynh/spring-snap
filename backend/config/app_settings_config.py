import os

from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()
env = os.getenv

class Settings(BaseSettings):
    env = "dev" # "prod" in production
    app_name = "Spring Snap"
    cors_origins = ["https://springsnap.org"] if env == "prod" else ["http://localhost:3000", "https://springsnap.org"]
    trusted_hosts = ["api.springsnap.org"] if env == "prod" else ["localhost", "127.0.0.1", "api.springsnap.org"]
    
    csrf_secret_key = env("APP_CSRF_SECRET_KEY")
    csrf_cookie_samesite = "lax"
    csrf_cookie_secure = True if env == "prod" else False
    csrf_token_location = "header"
    
    rate_slowapi_limiter = "50/minute"
