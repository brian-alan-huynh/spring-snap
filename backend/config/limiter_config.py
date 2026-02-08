from slowapi import Limiter
from slowapi.util import get_remote_address
from config.app_settings_config import Settings

settings = Settings()

limiter = Limiter(
    key_func=get_remote_address,
    default_limits=[settings.rate_slowapi_limiter],
)
