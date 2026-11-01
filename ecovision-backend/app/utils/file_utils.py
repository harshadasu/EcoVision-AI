import os
import uuid
import shutil
from pathlib import Path
from PIL import Image
from fastapi import UploadFile, HTTPException, status
from app.config import get_settings

settings = get_settings()


def generate_unique_filename(original_name: str) -> str:
    ext = Path(original_name).suffix.lower()
    if not ext:
        ext = ".jpg"
    return f"{uuid.uuid4().hex}{ext}"


def get_file_size_mb(file_path: str) -> float:
    if not os.path.exists(file_path):
        return 0.0
    return os.path.getsize(file_path) / (1024 * 1024)


def validate_image(file_path: str) -> bool:
    try:
        with Image.open(file_path) as img:
            img.verify()
        return True
    except Exception:
        return False


def save_upload_file(upload_file: UploadFile, destination_dir: str = None) -> str:
    if destination_dir is None:
        destination_dir = settings.UPLOAD_DIR

    os.makedirs(destination_dir, exist_ok=True)
    filename = generate_unique_filename(upload_file.filename or "upload.jpg")
    full_path = os.path.join(destination_dir, filename)

    with open(full_path, "wb") as buffer:
        shutil.copyfileobj(upload_file.file, buffer)

    size_mb = get_file_size_mb(full_path)
    if size_mb > settings.MAX_UPLOAD_MB:
        try:
            os.remove(full_path)
        except OSError:
            pass
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail=f"File exceeds maximum allowed size of {settings.MAX_UPLOAD_MB}MB",
        )

    if not validate_image(full_path):
        try:
            os.remove(full_path)
        except OSError:
            pass
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Uploaded file is not a valid image format",
        )

    # Return normalized relative path with forward slashes for URL and db consistency
    relative_path = os.path.relpath(full_path, start=os.getcwd()).replace("\\", "/")
    if relative_path.startswith("./"):
        relative_path = relative_path[2:]
    return relative_path
