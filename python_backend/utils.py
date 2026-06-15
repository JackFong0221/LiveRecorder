"""Utility functions."""
import os
import platform
import re


def clean_name(name: str, fallback: str | None = None) -> str:
    if not name:
        return fallback or ""
    illegal_chars = r'[<>:"/\\|?*]'
    cleaned = re.sub(illegal_chars, "_", name)
    cleaned = cleaned.strip()
    return cleaned or (fallback or "")


def get_query_params(url: str, key: str) -> list[str]:
    match = re.findall(rf"[?&]{key}=([^&]+)", url)
    return match


def open_folder(path: str) -> bool:
    if not os.path.exists(path):
        return False
    system = platform.system()
    if system == "Darwin":
        os.system(f'open "{path}"')
        return True
    elif system == "Windows":
        os.startfile(path)
        return True
    return False
