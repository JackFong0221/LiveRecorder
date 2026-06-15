"""Live stream recorder: manages FFmpeg subprocess for recording."""
import asyncio
import os
import re
import signal
import time
import subprocess
from datetime import datetime

from .ffmpeg_builder import build_ffmpeg_command, build_mp4_conversion_command
from .utils import clean_name, get_query_params
from .logger import logger
from .models import Recording, RecordingState, Settings


class StreamRecorder:
    def __init__(
        self,
        rec: Recording,
        settings: Settings,
        save_path: str,
        manager=None,
    ):
        self.recording = rec
        self.settings = settings
        self.output_dir = save_path
        self.proxy = settings.proxy_address if settings.enable_proxy else ""
        self.process: asyncio.subprocess.Process | None = None
        self.should_stop = False
        self.recording_start_time = 0.0
        self._manager = manager

    async def start(self, stream_data: dict):
        record_url = self._select_source_url(stream_data)
        logger.info(f"Record URL: {record_url[:150] if record_url else 'EMPTY'}")

        if not record_url:
            self._fail("No valid stream URL")
            return

        filename = self._build_filename(stream_data)
        output_dir = self._build_output_dir(stream_data)
        os.makedirs(output_dir, exist_ok=True)

        save_format = self.settings.video_format.lower()
        save_file = os.path.join(output_dir, filename + f".{save_format}")

        self.recording.recording_dir = output_dir
        self.recording.start_time = datetime.now().isoformat()
        self.recording.state = RecordingState.RECORDING
        self.recording.is_recording = True

        command = build_ffmpeg_command(
            record_url=record_url,
            save_format=save_format,
            full_path=save_file,
            segment_record=self.recording.segment_record,
            segment_time=self.recording.segment_time,
            proxy=self.proxy or None,
        )

        logger.info(f"Recording: {self.recording.url}")
        logger.info(f"Save path: {save_file}")

        ok = await self._run_ffmpeg(command, save_file)
        if not ok:
            self._fail(f"FFmpeg failed for {save_file}")

    def _fail(self, msg: str):
        logger.error(msg)
        self.recording.state = RecordingState.ERROR
        self.recording.is_recording = False
        if self._manager and self.recording.rec_id in self._manager._active_recorders:
            del self._manager._active_recorders[self.recording.rec_id]

    def _select_source_url(self, stream_data: dict) -> str:
        flv_url = stream_data.get("flv_url")
        prefer_flv = (
            self.settings.default_live_source == "FLV"
            and self.recording.platform_key in ("douyin", "tiktok")
        )

        if prefer_flv and flv_url:
            codec = get_query_params(flv_url, "codec")
            if codec and codec[0] == "h265":
                logger.warning("FLV h265 unsupported, using HLS")
                return stream_data.get("record_url") or stream_data.get("m3u8_url", "")
            return flv_url
        return stream_data.get("record_url") or stream_data.get("m3u8_url", "")

    def _build_filename(self, stream_data: dict) -> str:
        anchor = clean_name(stream_data.get("anchor_name", ""), "live_room")
        now = time.strftime("%Y-%m-%d_%H-%M-%S")
        return "_".join(filter(None, [anchor, now])).replace(" ", "_")

    def _build_output_dir(self, stream_data: dict) -> str:
        path = self.output_dir.rstrip("/")
        if self.settings.folder_by_platform:
            platform = stream_data.get("platform", self.recording.platform)
            path = os.path.join(path, platform)
        if self.settings.folder_by_author:
            anchor = clean_name(stream_data.get("anchor_name", ""), "live_room")
            path = os.path.join(path, anchor)
        return path

    async def _run_ffmpeg(self, command: list[str], save_file: str) -> bool:
        self.should_stop = False
        self.recording_start_time = time.time()

        try:
            self.process = await asyncio.create_subprocess_exec(
                *command,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )

            stderr_task = asyncio.create_task(self._collect_stderr())
            _stdout_task = asyncio.create_task(self._drain(self.process.stdout))

            while self.process.returncode is None:
                if self.should_stop:
                    await self._stop_process()
                    break
                await asyncio.sleep(0.5)

            return_code = self.process.returncode
            await asyncio.sleep(0.5)
            if not stderr_task.done():
                stderr_task.cancel()

            if return_code in (0, 255):
                logger.info(f"Recording finished: {save_file}")
                await self._post_process(save_file)
                return True
            else:
                self.recording.state = RecordingState.ERROR
                return False

        except Exception as e:
            logger.error(f"Recording error: {e}")
            return False
        finally:
            self.recording.is_recording = False
            self.recording.speed = "X KB/s"
            if self._manager and self.recording.rec_id in self._manager._active_recorders:
                del self._manager._active_recorders[self.recording.rec_id]

    async def _collect_stderr(self):
        last_lines = []
        while self.process and self.process.stderr:
            line = await self.process.stderr.readline()
            if not line:
                break
            decoded = line.decode("utf-8", errors="replace")
            # Always log FFmpeg errors/warnings
            if any(kw in decoded for kw in ("error", "Error", "fail", "Invalid", "No such", "Connection refused", "HTTP error", "Server returned")):
                logger.error(f"FFmpeg: {decoded.strip()}")
            if "speed=" in decoded:
                m = re.search(r"speed=([\d.]+)x", decoded)
                if m:
                    self.recording.speed = f"{m.group(1)}x"
            last_lines.append(decoded.strip())
            if len(last_lines) > 5:
                last_lines.pop(0)
        # Log last few lines on exit
        if last_lines:
            logger.info(f"FFmpeg last output: {' | '.join(last_lines)}")

    async def _drain(self, stream):
        if stream:
            while True:
                chunk = await stream.read(4096)
                if not chunk:
                    break

    async def _stop_process(self):
        if self.process and self.process.returncode is None:
            try:
                if os.name != "nt":
                    self.process.send_signal(signal.SIGINT)
                else:
                    if self.process.stdin:
                        self.process.stdin.write(b"q")
                        await self.process.stdin.drain()
                await asyncio.wait_for(self.process.wait(), timeout=10.0)
            except asyncio.TimeoutError:
                self.process.kill()
                await self.process.wait()

    async def _post_process(self, save_file: str):
        if self.settings.convert_to_mp4 and save_file.endswith(".ts"):
            mp4_file = save_file.rsplit(".", 1)[0] + ".mp4"
            if os.path.exists(save_file) and os.path.getsize(save_file) > 0:
                logger.info(f"Converting to mp4: {mp4_file}")
                proc = await asyncio.create_subprocess_exec(
                    *build_mp4_conversion_command(save_file, mp4_file),
                    stdout=asyncio.subprocess.DEVNULL,
                    stderr=asyncio.subprocess.DEVNULL,
                )
                await proc.wait()
                if proc.returncode == 0 and self.settings.delete_original:
                    os.remove(save_file)

    def stop(self):
        self.should_stop = True
