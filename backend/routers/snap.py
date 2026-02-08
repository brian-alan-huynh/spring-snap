import re

from fastapi import APIRouter, Request, Response, Depends, UploadFile
from pydantic import BaseModel, Field, validator
from fastapi_csrf_protect import CsrfProtect

from config.limiter_config import limiter
from infra.db_tagging import MongoDB
from infra.storage import S3
from infra.sessions import Redis
from services.computer_vision import yolov11_detect_file_objects

router = APIRouter(
    prefix="/snap",
    tags=["snap"],
    responses={ 401: { "description": "Unauthorized" } },
)

# Pydantic models
class SnapData(BaseModel):
    file_url: str
    created_at: str
    file_size: int
    s3_key: str
    is_in_folder: bool
    tags: list[str]
    caption: str

class KeyAndCaption(BaseModel):
    s3_key: str
    caption: str = Field(..., min_length=1, max_length=300)
    
    @validator("caption")
    def validate_caption(cls, v):
        if not bool(re.fullmatch(r'^[A-Za-z0-9\s\.!\?\(\)\[\]@&%\^#\:;\+=\-_]+$', v)):
            raise ValueError("Caption can only contain letters, numbers, spaces, and special characters")
        
        return v.strip()

# Error handling
class SnapError(Exception):
    "Exception for snap operations"
    pass
    
def _raise_snap_operation_error(func_name: str, error: Exception, request: Request) -> None:
    error_message = f"Failed to perform snap operation in {func_name}: {error}"
    request.app.state.logger.log_error(error_message)
    raise SnapError(error_message) from error

@router.get("/all", response_model=list[SnapData])
@limiter.limit("30/minute")
async def all(request: Request):
    try:
        session_key = request.cookies.get("session_key")
        
        session = Redis.get_session(session_key, request)
        user_id = session["user_id"]
        
        snaps = S3.read_snaps(user_id, request)
        snaps_tags_and_captions = MongoDB.read_file_tags_and_captions(user_id, request)
        
        snaps_with_tags_and_captions = []
        
        for snap, tags_and_caption in zip(snaps, snaps_tags_and_captions):
            snaps_with_tags_and_captions.append({
                "file_url": snap["file_url"],
                "created_at": snap["created_at"],
                "file_size": snap["file_size"],
                "s3_key": snap["s3_key"],
                "is_in_folder": snap["is_in_folder"],
                "tags": tags_and_caption["tags"],
                "caption": tags_and_caption["caption"],
            })
        
        return snaps_with_tags_and_captions
    
    except Exception as e:
        _raise_snap_operation_error("all", e, request)

@router.post("/upload")
@limiter.limit("325/minute")
async def upload(
    request: Request,
    file: UploadFile,
    folder_name: str | None = None,
    csrf_protect: CsrfProtect = Depends(),
):
    await csrf_protect.validate_csrf(request)
    
    try:
        session_key = request.cookies.get("session_key")
        
        session = Redis.get_session(session_key, request)
        user_id = session["user_id"]
        
        file_url, s3_key = await S3.upload_snap(user_id, file, folder_name, request)
        Redis.place_thumbnail_file_url(session_key, file_url, request)
        tags = await yolov11_detect_file_objects(file, request)
        MongoDB.add_file_tags(user_id, s3_key, tags, request)
        
        return Response(status_code=200)
        
    except Exception as e:
        _raise_snap_operation_error("upload", e, request)

@router.post("/caption")
@router.put("/caption")
@limiter.limit("50/minute")
async def caption(
    request: Request,
    key_and_caption: KeyAndCaption,
    csrf_protect: CsrfProtect = Depends(),
):
    await csrf_protect.validate_csrf(request)
    
    try:
        s3_key = key_and_caption.s3_key
        caption = key_and_caption.caption
        
        MongoDB.write_file_caption(s3_key, caption, request)
        
        return Response(status_code=200)
        
    except Exception as e:
        _raise_snap_operation_error("caption", e, request)
    
@router.delete("/single")
async def delete_single(
    request: Request,
    s3_key: str,
    csrf_protect: CsrfProtect = Depends(),
):
    await csrf_protect.validate_csrf(request)
    
    try:
        S3.delete_snap(s3_key, request)
        MongoDB.delete_file_tags_and_captions(s3_key, request)
        
        return Response(status_code=200)
    
    except Exception as e:
        _raise_snap_operation_error("delete_single", e, request)
