"""Platform handler: wraps streamget for live stream detection and URL extraction."""
import re
from typing import Any

import streamget

from .logger import logger
from .config import ConfigManager

# Platform URL patterns → (display_name, platform_key)
PLATFORM_MAP: dict[str, tuple[str, str]] = {
    "douyin.com/": ("抖音直播", "douyin"),
    "tiktok.com/": ("TikTok直播", "tiktok"),
    "live.kuaishou.com/": ("快手直播", "kuaishou"),
    "huya.com/": ("虎牙直播", "huya"),
    "douyu.com/": ("斗鱼直播", "douyu"),
    "yy.com/": ("YY直播", "yy"),
    "live.bilibili.com/": ("B站直播", "bilibili"),
    "xiaohongshu.com/": ("小红书直播", "rednote"),
    "xhslink.com/": ("小红书直播", "xhs"),
    "bigo.tv/": ("Bigo直播", "bigo"),
    "sooplive.co.kr/": ("SOOP", "soop"),
    "sooplive.com/": ("SOOP", "soop"),
    "pandalive.co.kr/": ("PandaTV", "pandalive"),
    "twitch.tv/": ("Twitch", "twitch"),
    "flextv.co.kr/": ("FlexTV", "flextv"),
    "popkontv.com/": ("PopkonTV", "popkontv"),
    "twitcasting.tv/": ("TwitCasting", "twitcasting"),
    "youtube.com/": ("YouTube", "youtube"),
    "showroom-live.com/": ("ShowRoom", "showroom"),
    "17.live/": ("17Live", "17live"),
    "liveme.com/": ("LiveMe", "liveme"),
    "chzzk.naver.com/": ("CHZZK", "chzzk"),
}

# Platforms that need proxy
PROXY_PLATFORMS = {
    "tiktok", "soop", "pandalive", "winktv", "flextv", "popkontv",
    "twitch", "liveme", "showroom", "chzzk", "youtube", "lang",
}


def detect_platform(url: str) -> tuple[str | None, str | None]:
    """Detect platform name and key from a URL."""
    for pattern, (name, key) in PLATFORM_MAP.items():
        if pattern in url:
            return name, key
    if ".m3u8" in url or ".flv" in url:
        return "自定义直播", "custom"
    return None, None


class PlatformDetector:
    def __init__(self, config: ConfigManager):
        self.config = config

    def _get_proxy(self, platform_key: str) -> str | None:
        settings = self.config.settings
        if settings.enable_proxy and settings.proxy_address and platform_key in PROXY_PLATFORMS:
            return settings.proxy_address
        return None

    def _get_cookie(self, platform_key: str) -> str | None:
        return self.config.get_cookie(platform_key)

    async def fetch_stream_info(self, url: str, platform_key: str | None = None, quality: str = "OD") -> dict[str, Any]:
        """Fetch stream info for a live URL. Returns a dict with stream data."""
        if platform_key is None:
            _, platform_key = detect_platform(url)
            if not platform_key:
                return {}

        proxy = self._get_proxy(platform_key)
        cookie = self._get_cookie(platform_key)

        # Short link resolution
        actual_url = url

        # Build handler
        handler_class = self._get_handler_class(platform_key, actual_url)
        if handler_class is None:
            logger.error(f"No handler for platform: {platform_key}")
            return {}

        try:
            handler = handler_class(proxy_addr=proxy, cookies=cookie)
            # Douyin short links need different fetch method
            if platform_key == "douyin":
                if "v.douyin.com" in url or "www.douyin.com/user" in url:
                    json_data = await handler.fetch_app_stream_data(url=actual_url)
                else:
                    json_data = await handler.fetch_web_stream_data(url=actual_url)
            else:
                json_data = await handler.fetch_web_stream_data(url=actual_url)
            stream_data = await handler.fetch_stream_url(json_data, quality)
            return self._serialize_stream_data(stream_data)
        except Exception as e:
            logger.error(f"Failed to fetch stream info for {url}: {e}")
            return {}

    @staticmethod
    def _get_handler_class(platform_key: str, url: str):
        if platform_key == "douyin":
            return streamget.DouyinLiveStream
        elif platform_key == "tiktok":
            return streamget.TikTokLiveStream
        elif platform_key == "kuaishou":
            return streamget.KwaiLiveStream
        elif platform_key == "huya":
            return streamget.HuyaLiveStream
        elif platform_key == "douyu":
            return streamget.DouyuLiveStream
        elif platform_key == "bilibili":
            return streamget.BilibiliLiveStream
        elif platform_key in ("rednote", "xhs"):
            return streamget.RedNoteLiveStream
        elif platform_key == "bigo":
            return streamget.BigoLiveStream
        elif platform_key == "soop":
            return streamget.SoopLiveStream
        elif platform_key == "pandalive":
            return streamget.PandaLiveStream
        elif platform_key == "twitch":
            return streamget.TwitchLiveStream
        elif platform_key == "flextv":
            return streamget.FlexTVLiveStream
        elif platform_key == "popkontv":
            return streamget.PopkonTVLiveStream
        elif platform_key == "twitcasting":
            return streamget.TwitCastingLiveStream
        elif platform_key == "youtube":
            return streamget.YoutubeLiveStream
        elif platform_key == "showroom":
            return streamget.ShowRoomLiveStream
        elif platform_key == "liveme":
            return streamget.LiveMeLiveStream
        elif platform_key == "chzzk":
            return streamget.ChzzkLiveStream
        elif platform_key == "blued":
            return streamget.BluedLiveStream
        elif platform_key == "netease":
            return streamget.NeteaseLiveStream
        elif platform_key == "yy":
            return streamget.YYLiveStream
        elif platform_key == "huajiao":
            return streamget.HuajiaoLiveStream
        elif platform_key == "shopee":
            return streamget.ShopeeLiveStream
        elif platform_key == "custom":
            return _CustomHandler
        return None

    @staticmethod
    def _serialize_stream_data(sd) -> dict[str, Any]:
        return {
            "platform": getattr(sd, "platform", ""),
            "anchor_name": getattr(sd, "anchor_name", ""),
            "is_live": getattr(sd, "is_live", False),
            "title": getattr(sd, "title", None),
            "quality": getattr(sd, "quality", None),
            "m3u8_url": getattr(sd, "m3u8_url", None),
            "flv_url": getattr(sd, "flv_url", None),
            "record_url": getattr(sd, "record_url", None),
        }


class _CustomHandler:
    """Handler for direct M3U8/FLV URLs."""
    def __init__(self, proxy_addr=None, cookies=None):
        self.proxy_addr = proxy_addr
        self.cookies = cookies

    async def fetch_web_stream_data(self, url):
        return {"url": url}

    async def fetch_stream_url(self, data, quality):
        url = data.get("url", "")
        from streamget import StreamData
        return StreamData(
            platform="Custom",
            anchor_name="CustomLive",
            is_live=True,
            record_url=url,
            m3u8_url=url if ".m3u8" in url else None,
            flv_url=url if ".flv" in url else None,
        )
