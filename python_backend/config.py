"""Configuration manager for the recording daemon."""
import json
import os
from typing import Any

from .models import Settings, Recording
from .logger import logger

DEFAULT_SETTINGS = Settings()


class ConfigManager:
    def __init__(self, config_dir: str):
        self.config_dir = config_dir
        os.makedirs(self.config_dir, exist_ok=True)

        self.settings_path = os.path.join(self.config_dir, "settings.json")
        self.recordings_path = os.path.join(self.config_dir, "recordings.json")
        self.cookies_path = os.path.join(self.config_dir, "cookies.json")

        self._settings: Settings | None = None
        self._recordings: list[Recording] = []
        self._cookies: dict[str, str] = {}

        self._init_files()
        self._load()

    def _init_files(self):
        for path in (self.settings_path, self.recordings_path, self.cookies_path):
            if not os.path.exists(path):
                with open(path, "w", encoding="utf-8") as f:
                    json.dump({}, f, ensure_ascii=False, indent=2)

    def _load(self):
        self._settings = self._load_json(self.settings_path, Settings.from_dict)
        self._cookies = self._load_json(self.cookies_path)

        raw = self._load_json(self.recordings_path)
        if isinstance(raw, list):
            self._recordings = [Recording.from_dict(r) for r in raw]
        else:
            self._recordings = []

    def _load_json(self, path: str, converter=None) -> Any:
        try:
            with open(path, encoding="utf-8") as f:
                data = json.load(f)
            if converter and isinstance(data, dict):
                return converter(data)
            return data
        except Exception as e:
            logger.error(f"Failed to load {path}: {e}")
            return {} if converter else ([], data)[0]

    def _save_json(self, path: str, data: Any):
        with open(path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    @property
    def settings(self) -> Settings:
        return self._settings

    @property
    def recordings(self) -> list[Recording]:
        return self._recordings

    @property
    def cookies(self) -> dict[str, str]:
        return self._cookies

    def get_cookie(self, platform_key: str) -> str | None:
        return self._cookies.get(platform_key)

    def update_settings(self, data: dict) -> Settings:
        current = self._settings.to_dict()
        current.update({k: v for k, v in data.items() if k in current})
        self._settings = Settings.from_dict(current)
        self._save_json(self.settings_path, self._settings.to_dict())
        return self._settings

    def add_recording(self, rec: Recording) -> Recording:
        self._recordings.append(rec)
        self._persist_recordings()
        return rec

    def remove_recording(self, rec_id: str) -> bool:
        self._recordings = [r for r in self._recordings if r.rec_id != rec_id]
        self._persist_recordings()
        return True

    def find_recording(self, rec_id: str) -> Recording | None:
        for r in self._recordings:
            if r.rec_id == rec_id:
                return r
        return None

    def update_recording(self, rec_id: str, updates: dict) -> Recording | None:
        rec = self.find_recording(rec_id)
        if rec:
            for k, v in updates.items():
                if hasattr(rec, k):
                    setattr(rec, k, v)
            self._persist_recordings()
        return rec

    def _persist_recordings(self):
        self._save_json(self.recordings_path, [r.to_dict() for r in self._recordings])

    def save_cookies(self, platform: str, cookie_str: str):
        self._cookies[platform] = cookie_str
        self._save_json(self.cookies_path, self._cookies)

    def get_video_save_path(self) -> str:
        return self._settings.video_save_path or os.path.join(
            os.path.dirname(self.config_dir), "downloads"
        )
