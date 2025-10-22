import os

from fastapi import Request
from dotenv import load_dotenv

from infra.sessions import Redis
from infra.storage import S3

load_dotenv()
env = os.getenv

class OAuthError(Exception):
    "Exception for OAuth operations"
    pass

def update_thumbnail(user_id: int, session_key: str, request: Request) -> None:
    most_recent_snap = S3.read_newest_snap(user_id, request)

    if most_recent_snap == "":
        return
    
    Redis.place_thumbnail_file_url(session_key, most_recent_snap, request)
    return

def signup_or_login_oauth(
        first_name: str,
        provider: str,
        oauth_user_id: int,
        request: Request,
    ) -> str:

    try:
        user_id = request.app.state.rds.check_and_fetch_oauth_login_creds(oauth_user_id, request)
        new_account = True
            
        if not user_id:
            new_user_id = request.app.state.rds.create_user(
                request,
                first_name=first_name,
                oauth_provider=provider,
                oauth_provider_user_id=oauth_user_id,
            )
            
            request.app.state.rds.create_user_preference(new_user_id, "light", request)
            
            user_id = new_user_id
            
        else:
            new_account = False
        
        session_key = Redis.add_new_session(user_id, request)
         
        if not new_account:
            update_thumbnail(user_id, session_key, request)
            
        return session_key
        
    except Exception as e:
        error_message = f"Failed to perform OAuth operation: {e}"
        request.app.state.logger.log_error(error_message)
        raise OAuthError(error_message) from e
    
def redirect_and_set_cookie(session_key: str, oauth_provider: str | None = None) -> RedirectResponse:
    response = RedirectResponse(url=f"{env("FRONTEND_DOMAIN_NAME")}/home", status_code=302)
    
    response.set_cookie(
        key="session_key",
        value=session_key,
        httponly=True,
        secure=True,
        same_site="lax",
        max_age=60 * 60 * 24 * 7 * 4 * 6,
    )
    
    if oauth_provider:
        response.set_cookie(
            key="recently_used_oauth_provider",
            value=oauth_provider,
            httponly=True,
            secure=True,
            same_site="lax",
            max_age=60 * 60 * 24 * 7 * 4 * 6 * 2,
        )
    
    return response
