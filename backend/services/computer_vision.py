import os
import base64

import requests as req
from dotenv import load_dotenv
from fastapi import UploadFile, Request

class YOLOv11Error(Exception):
    "Exception for YOLOv11 operations"
    pass

def yolov11_error_handler(error: Exception | None, request: Request) -> None:
    if error:
        error_message = f"Failed to perform YOLOv11 detection in yolov11_detect_file_objects: {error}"
        request.app.state.logger.log_error(error_message)
        raise YOLOv11Error(error_message) from error

    else:
        error_message = "Failed to perform YOLOv11 detection in yolov11_detect_file_objects"
        request.app.state.logger.log_error(error_message)
        raise YOLOv11Error(error_message)

load_dotenv()
env = os.getenv

async def yolov11_detect_file_objects(file: UploadFile, request: Request) -> list[str]:
    try:
        file_content = await file.read()
        file_base64 = str(base64.b64encode(file_content).decode("utf-8"))
        
        res = req.post(
            f"https://detect.roboflow.com/{env("ROBOFLOW_MODEL_PATH")}",
            headers={
                "User-Agent": f"CurbyStorage/0.1.0 (https://curbystorage.com; {env("EMAIL")})",
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept-Language": "en-US",
            },
            params={
                "overlap": 0.5,
                "confidence": 0.35,
                "api-key": env("ROBOFLOW_API_KEY"),
            },
            data=file_base64,
        )
        
        if res.status_code != 200:
            yolov11_error_handler(None, request)
        
        data = res.json()
        
        tags = []
        
        for obj in data["predictions"]:
            tags.append(obj["class"])
        
        return tags
    
    except YOLOv11Error:
        raise
    
    except Exception as e:
        yolov11_error_handler(e, request)
