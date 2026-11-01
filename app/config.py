# EcoVision AI - Configuration
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    APP_NAME: str = "EcoVision AI"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Model settings
    EMBEDDING_MODEL: str = "all-MiniLM-L6-v2"
    IMAGE_MODEL: str = "google/vit-base-patch16-224"

    # FAISS index path
    FAISS_INDEX_PATH: str = "data/faiss_index"

    # File upload limits
    MAX_UPLOAD_SIZE_MB: int = 20

    class Config:
        env_file = ".env"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
