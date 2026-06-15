"""Recording daemon server: FastAPI REST API for the SwiftUI frontend."""
import os
import sys
import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .config import ConfigManager
from .manager import RecordingManager
from .logger import logger

# Determine config directory
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_DIR = os.environ.get("LIVERECORDER_CONFIG_DIR", os.path.join(BASE_DIR, "config"))
# Remove old StreamCap config directory reference
if "StreamCap" in CONFIG_DIR:
    CONFIG_DIR = os.path.join(os.path.dirname(BASE_DIR) if "StreamCap" in BASE_DIR else BASE_DIR, "LiveRecorder_config")

# Override: use our own config dir
CONFIG_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "config")

_config: ConfigManager | None = None
_manager: RecordingManager | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Strip proxy env vars — streamget's httpx picks them up automatically
    for key in list(os.environ.keys()):
        if key.lower().endswith('_proxy'):
            os.environ.pop(key, None)

    global _config, _manager
    _config = ConfigManager(CONFIG_DIR)
    _manager = RecordingManager(_config)
    _manager.start_periodic_check()
    logger.info(f"Recording daemon started. Config: {CONFIG_DIR}")
    yield
    logger.info("Recording daemon shutting down...")


app = FastAPI(title="LiveRecorder Daemon", version="0.1.0", lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def _mgr() -> RecordingManager:
    if _manager is None:
        raise HTTPException(500, "Daemon not initialized")
    return _manager


def _cfg() -> ConfigManager:
    if _config is None:
        raise HTTPException(500, "Daemon not initialized")
    return _config


# ── Health ──────────────────────────────────────────────

@app.get("/api/status")
async def health():
    mgr = _mgr()
    return {
        "status": "running",
        "recording_count": len(mgr.recordings),
    }


# ── Recordings ─────────────────────────────────────────

class AddRecordingBody(BaseModel):
    url: str
    quality: str = "OD"
    record_format: str = "ts"


@app.post("/api/recordings")
async def add_recording(body: AddRecordingBody):
    mgr = _mgr()
    rec = await mgr.add_recording(
        url=body.url,
        quality=body.quality,
        record_format=body.record_format,
    )
    return {"status": "ok", "recording": rec.to_dict()}


@app.get("/api/recordings")
async def list_recordings():
    return [item for item in _mgr().get_recordings_dict()]


@app.delete("/api/recordings/{rec_id}")
async def delete_recording(rec_id: str):
    mgr = _mgr()
    if not mgr.remove_recording(rec_id):
        raise HTTPException(404, "Recording not found")
    return {"status": "ok"}


class UpdateRecordingBody(BaseModel):
    quality: str | None = None
    record_format: str | None = None


@app.put("/api/recordings/{rec_id}")
async def update_recording(rec_id: str, body: UpdateRecordingBody):
    cfg = _cfg()
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    rec = cfg.update_recording(rec_id, updates)
    if rec is None:
        raise HTTPException(404, "Recording not found")
    return {"status": "ok", "recording": rec.to_dict()}


@app.post("/api/recordings/{rec_id}/start")
async def start_monitoring(rec_id: str):
    await _mgr().start_monitoring(rec_id)
    return {"status": "ok"}


@app.post("/api/debug/stream")
async def debug_stream(body: dict):
    """Debug: test stream detection and return full data."""
    url = body.get("url", "")
    quality = body.get("quality", "OD")
    from .platforms import detect_platform
    platform, platform_key = detect_platform(url)
    cfg = _cfg()
    detector = PlatformDetector(cfg)
    data = await detector.fetch_stream_info(url, platform_key, quality)
    return {
        "platform": platform,
        "platform_key": platform_key,
        "data": data,
        "proxy_enabled": cfg.settings.enable_proxy,
        "proxy_address": cfg.settings.proxy_address,
    }


@app.post("/api/recordings/{rec_id}/stop")
async def stop_monitoring(rec_id: str):
    await _mgr().stop_monitoring(rec_id)
    return {"status": "ok"}


@app.post("/api/recordings/{rec_id}/stop-recording")
async def stop_recording(rec_id: str):
    await _mgr().stop_recording(rec_id)
    return {"status": "ok"}


@app.get("/api/recordings/{rec_id}/files")
async def list_recording_files(rec_id: str):
    return _mgr().get_recording_files(rec_id)


# ── Settings ───────────────────────────────────────────

@app.get("/api/settings")
async def get_settings():
    return _cfg().settings.to_dict()


@app.put("/api/settings")
async def update_settings(body: dict):
    cfg = _cfg()
    cfg.update_settings(body)
    return {"status": "ok", "settings": cfg.settings.to_dict()}


# ── Cookies ────────────────────────────────────────────

@app.get("/api/cookies")
async def get_cookies():
    return _cfg().cookies


@app.put("/api/cookies/{platform}")
async def set_cookie(platform: str, body: dict):
    cookie = body.get("cookie", "")
    _cfg().save_cookies(platform, cookie)
    return {"status": "ok"}


# ── Platforms ──────────────────────────────────────────

@app.post("/api/detect")
async def detect_url(body: dict):
    """Detect platform info from a URL."""
    url = body.get("url", "")
    from .platforms import detect_platform
    platform, platform_key = detect_platform(url)
    return {"platform": platform, "platform_key": platform_key}


def main():
    import uvicorn
    port = int(os.environ.get("LIVERECORDER_PORT", "6006"))
    uvicorn.run("python_backend.server:app", host="127.0.0.1", port=port, reload=False)


if __name__ == "__main__":
    main()
