import os

from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()
env = os.getenv

class Settings(BaseSettings):
    environment: str = env("ENVIRONMENT")
    app_name = "Curby Storage"
    cors_origins = ["https://curbystorage.com"] if environment == "prod" else ["http://localhost:3000", "https://curbystorage.com"]
    trusted_hosts = ["api.curbystorage.com"] if environment == "prod" else ["localhost", "127.0.0.1", "api.curbystorage.com"]

    csrf_secret_key: str = env("APP_CSRF_SECRET_KEY")
    csrf_cookie_samesite = "lax"
    csrf_cookie_secure = True if environment == "prod" else False
    csrf_token_location = "header"

    rate_slowapi_limiter = "50/minute"
