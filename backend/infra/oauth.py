import os

from authlib.integrations.starlette_client import OAuth
from dotenv import load_dotenv

load_dotenv()
env = os.getenv

oauth = OAuth()

oauth.register(
    name="google",
    client_id=env("GOOGLE_CLIENT_ID"),
    client_secret=env("GOOGLE_CLIENT_SECRET"),
    server_metadata_url="https://accounts.google.com/.well-known/openid-configuration",
    client_kwargs={
        "scope": "openid email profile",
        "prompt": "select_account",
    }
)
