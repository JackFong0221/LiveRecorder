"""Logging utility."""
import sys
from loguru import logger as _logger

_logger.remove()
_logger.add(
    sys.stderr,
    format="<green>{time:YYYY-MM-DD HH:mm:ss.SSS}</green> | <level>{level: <8}</level> | <level>{message}</level>",
    level="INFO",
)

logger = _logger
