"""Data models for the recording daemon."""
import uuid
from datetime import datetime, timedelta
from dataclasses import dataclass, field, asdict
from enum import Enum


class RecordingState(str, Enum):
    STOPPED = "stopped"
    MONITORING = "monitoring"
    RECORDING = "recording"
    CHECKING = "checking"
    ERROR = "error"
    LIVE = "live"
    OFFLINE = "offline"


@dataclass
class Recording:
    url: str
    rec_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    streamer_name: str = "直播间"
    title: str = ""
    platform: str = ""
    platform_key: str = ""
    quality: str = "OD"
    record_format: str = "ts"
    segment_record: bool = True
    segment_time: str = "1800"
    monitor_status: bool = True
    output_dir: str = ""
    recording_dir: str = ""
    is_live: bool = False
    is_recording: bool = False
    state: RecordingState = RecordingState.STOPPED
    speed: str = "X KB/s"
    duration: str = ""
    start_time: str = ""
    created_at: str = field(default_factory=lambda: datetime.now().isoformat())

    def to_dict(self) -> dict:
        d = asdict(self)
        d["state"] = self.state.value
        return d

    @classmethod
    def from_dict(cls, data: dict) -> "Recording":
        state = data.get("state", "stopped")
        data["state"] = RecordingState(state) if isinstance(state, str) else state
        filtered = {k: v for k, v in data.items() if k in cls.__dataclass_fields__}
        return cls(**filtered)


@dataclass
class Settings:
    video_save_path: str = ""
    video_format: str = "ts"
    record_quality: str = "OD"
    loop_time_seconds: int = 180
    segment_time: str = "1800"
    enable_proxy: bool = False
    proxy_address: str = ""
    convert_to_mp4: bool = True
    delete_original: bool = False
    default_live_source: str = "HLS"
    force_https: bool = True
    folder_by_platform: bool = True
    folder_by_author: bool = True

    def to_dict(self) -> dict:
        return asdict(self)

    @classmethod
    def from_dict(cls, data: dict) -> "Settings":
        filtered = {k: v for k, v in data.items() if k in cls.__dataclass_fields__}
        return cls(**filtered)
