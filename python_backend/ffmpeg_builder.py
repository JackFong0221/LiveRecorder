"""FFmpeg command builder for live stream recording."""

DEFAULT_CONFIG = {
    "rw_timeout": "15000000",
    "analyzeduration": "20000000",
    "probesize": "10000000",
    "bufsize": "8000k",
    "max_muxing_queue_size": "1024",
}

FFMPEG_USER_AGENT = (
    "Mozilla/5.0 (Linux; Android 11; SAMSUNG SM-G973U) AppleWebKit/537.36 "
    "(KHTML, like Gecko) SamsungBrowser/14.2 Chrome/87.0.4280.141 Mobile Safari/537.36"
)


def build_ffmpeg_command(
    record_url: str,
    save_format: str,
    full_path: str,
    *,
    segment_record: bool = False,
    segment_time: str = "1800",
    headers: str | None = None,
    proxy: str | None = None,
) -> list[str]:
    command = [
        "ffmpeg", "-y", "-v", "verbose",
        "-rw_timeout", DEFAULT_CONFIG["rw_timeout"],
        "-loglevel", "error", "-hide_banner",
        "-user_agent", FFMPEG_USER_AGENT,
        "-protocol_whitelist", "rtmp,crypto,file,http,https,tcp,tls,udp,rtp,httpproxy",
        "-thread_queue_size", "1024",
        "-analyzeduration", DEFAULT_CONFIG["analyzeduration"],
        "-probesize", DEFAULT_CONFIG["probesize"],
        "-fflags", "+discardcorrupt+igndts",
        "-re",
    ]

    if headers:
        command.extend(["-headers", headers])

    if proxy:
        command[1:1] = ["-http_proxy", proxy]

    command.extend([
        "-i", record_url,
        "-bufsize", DEFAULT_CONFIG["bufsize"],
        "-sn", "-dn",
        "-reconnect_delay_max", "60",
        "-reconnect_streamed", "-reconnect_at_eof",
        "-max_muxing_queue_size", DEFAULT_CONFIG["max_muxing_queue_size"],
        "-correct_ts_overflow", "1",
        "-avoid_negative_ts", "1",
        "-flush_packets", "1",
        "-c:v", "copy",
        "-c:a", "copy",
        "-map", "0",
    ])

    if segment_record:
        base = full_path.rsplit(".", 1)[0]
        full_path = base + "_%03d.ts"
        command.extend([
            "-f", "segment",
            "-segment_time", segment_time,
            "-segment_format", "mpegts",
            "-reset_timestamps", "1",
        ])
    else:
        container = "mpegts" if save_format == "ts" else save_format
        command.extend(["-f", container])

    command.append(full_path)
    return command


def build_mp4_conversion_command(input_path: str, output_path: str) -> list[str]:
    return [
        "ffmpeg", "-i", input_path,
        "-c:v", "copy", "-c:a", "copy",
        "-f", "mp4", output_path,
    ]
