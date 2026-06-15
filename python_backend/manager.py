"""Recording manager: orchestrates monitoring and recording lifecycle."""
import asyncio
import os
import glob
from datetime import datetime
from typing import Optional

from .config import ConfigManager
from .models import Recording, RecordingState
from .platforms import PlatformDetector, detect_platform
from .recorder import StreamRecorder
from .logger import logger


class RecordingManager:
    def __init__(self, config: ConfigManager):
        self.config = config
        self.detector = PlatformDetector(config)
        self._active_recorders: dict[str, StreamRecorder] = {}
        self._periodic_task: asyncio.Task | None = None
        self._running = False

    @property
    def recordings(self) -> list[Recording]:
        return self.config.recordings

    async def add_recording(self, url: str, **kwargs) -> Recording:
        url = url.strip().split(" ")[0]  # Remove trailing text
        platform, platform_key = detect_platform(url)

        rec = Recording(
            url=url,
            platform=platform or "",
            platform_key=platform_key or "",
            **kwargs,
        )

        self.config.add_recording(rec)

        # Try to resolve streamer name immediately
        if platform_key:
            await self._resolve_name(rec)

        # Start monitoring
        asyncio.create_task(self._monitor_loop(rec))
        return rec

    async def remove_recording(self, rec_id: str) -> bool:
        # Stop any active recorder
        if rec_id in self._active_recorders:
            self._active_recorders[rec_id].stop()
            del self._active_recorders[rec_id]

        return self.config.remove_recording(rec_id)

    async def start_monitoring(self, rec_id: str):
        rec = self.config.find_recording(rec_id)
        if rec:
            rec.monitor_status = True
            rec.state = RecordingState.MONITORING
            self.config._persist_recordings()
            asyncio.create_task(self._monitor_loop(rec))

    async def stop_monitoring(self, rec_id: str):
        rec = self.config.find_recording(rec_id)
        if rec:
            rec.monitor_status = False
            rec.state = RecordingState.STOPPED
            self.config._persist_recordings()
            if rec_id in self._active_recorders:
                self._active_recorders[rec_id].stop()
                del self._active_recorders[rec_id]

    async def stop_recording(self, rec_id: str):
        if rec_id in self._active_recorders:
            self._active_recorders[rec_id].stop()
            del self._active_recorders[rec_id]
        rec = self.config.find_recording(rec_id)
        if rec:
            rec.is_recording = False
            rec.state = RecordingState.MONITORING if rec.monitor_status else RecordingState.STOPPED
            self.config._persist_recordings()

    async def _resolve_name(self, rec: Recording):
        if rec.platform_key is None:
            return

        try:
            data = await self.detector.fetch_stream_info(
                rec.url, rec.platform_key, rec.quality
            )
            anchor = data.get("anchor_name", "")
            if anchor and rec.streamer_name == "直播间":
                rec.streamer_name = anchor
                rec.title = f"{anchor} - {rec.quality}"
                self.config._persist_recordings()
        except Exception:
            pass

    async def _monitor_loop(self, rec: Recording):
        interval = self.config.settings.loop_time_seconds

        while rec.monitor_status:
            await self._check_recording(rec)
            await asyncio.sleep(interval)

    async def _check_recording(self, rec: Recording):
        # Clean up stale recorder entry if FFmpeg already exited
        if rec.rec_id in self._active_recorders and not rec.is_recording:
            del self._active_recorders[rec.rec_id]

        if rec.is_recording or rec.rec_id in self._active_recorders:
            return

        rec.state = RecordingState.CHECKING

        try:
            data = await self.detector.fetch_stream_info(
                rec.url, rec.platform_key, rec.quality
            )
        except Exception as e:
            logger.error(f"Stream detection failed for {rec.url}: {e}")
            rec.state = RecordingState.MONITORING
            return

        if not data:
            rec.state = RecordingState.MONITORING
            return

        anchor = data.get("anchor_name", "")
        if anchor and rec.streamer_name == "直播间":
            rec.streamer_name = anchor
            rec.title = f"{anchor} - {rec.quality}"

        if data.get("is_live"):
            rec.is_live = True
            rec.state = RecordingState.LIVE

            # Start recording
            save_path = self.config.get_video_save_path()
            recorder = StreamRecorder(rec, self.config.settings, save_path, manager=self)
            self._active_recorders[rec.rec_id] = recorder
            asyncio.create_task(recorder.start(data))
        else:
            rec.is_live = False
            rec.state = RecordingState.MONITORING

        self.config._persist_recordings()

    def start_periodic_check(self):
        """Start periodic live status checking (driven externally)."""
        # The individual monitor loops handle periodic checking
        # This is called at startup to resume monitoring
        for rec in self.config.recordings:
            if rec.monitor_status:
                rec.state = RecordingState.MONITORING
                asyncio.create_task(self._monitor_loop(rec))

    def get_recording_files(self, rec_id: str) -> list[dict]:
        """List recorded files for a recording."""
        rec = self.config.find_recording(rec_id)
        if not rec or not rec.recording_dir:
            return []

        video_exts = {".ts", ".mp4", ".flv", ".mkv", ".mov"}
        files = []
        search_dir = rec.recording_dir
        if os.path.exists(search_dir):
            for f in sorted(glob.glob(os.path.join(search_dir, "**", "*"), recursive=True)):
                _, ext = os.path.splitext(f)
                if ext.lower() in video_exts:
                    files.append({
                        "name": os.path.basename(f),
                        "path": f,
                        "size": os.path.getsize(f),
                        "modified": datetime.fromtimestamp(os.path.getmtime(f)).isoformat(),
                    })
        return files

    def get_recordings_dict(self) -> list[dict]:
        return [r.to_dict() for r in self.config.recordings]

    def get_active_recorder(self, rec_id: str) -> StreamRecorder | None:
        return self._active_recorders.get(rec_id)
