#!/usr/bin/env python3
"""
Cross-Platform Lightweight Media Validator for KIRI Engine 3D Reconstruction.
Compatible with Windows, macOS, and Linux.
Zero external dependencies: no ffmpeg, no OpenCV, no pip packages.
Uses pure-Python MP4/MOV atom parser as universal core, with macOS mdls helper.
"""

import sys
import os
import json
import struct
import subprocess
from pathlib import Path

# Ensure UTF-8 output on Windows consoles
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

# Limits as defined by KIRI Engine WebApp
MAX_SIZE_BYTES = 5 * 1024 * 1024 * 1024  # 5 GB
MIN_PHOTOS = 20
MAX_PHOTOS = 300
MIN_VIDEO_DURATION = 3.0  # 3 seconds
MAX_VIDEO_DURATION = 180.0  # 3 minutes

IMAGE_EXTENSIONS = {
    ".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp",
    ".dng", ".tiff", ".tif", ".bmp"
}

VIDEO_EXTENSIONS = {
    ".mp4", ".mov", ".m4v", ".avi", ".mkv", ".webm"
}


def parse_mp4_duration(file_path: str) -> float:
    """
    Pure Python parser to read duration from MP4/MOV 'mvhd' atom without external tools.
    Works natively on Windows, Linux, and macOS.
    """
    try:
        with open(file_path, "rb") as f:
            file_size = os.path.getsize(file_path)
            while f.tell() < file_size:
                header = f.read(8)
                if len(header) < 8:
                    break
                atom_size, atom_type = struct.unpack(">I4s", header)
                atom_type_str = atom_type.decode("latin1", errors="ignore")

                if atom_size == 1:
                    # 64-bit extended size
                    extended_size = f.read(8)
                    atom_size = struct.unpack(">Q", extended_size)[0]
                    content_size = atom_size - 16
                elif atom_size == 0:
                    content_size = file_size - f.tell()
                else:
                    content_size = atom_size - 8

                if content_size < 0:
                    break

                if atom_type_str == "moov":
                    # Search inside moov container for mvhd
                    moov_end = f.tell() + content_size
                    while f.tell() < moov_end:
                        sub_header = f.read(8)
                        if len(sub_header) < 8:
                            break
                        sub_size, sub_type = struct.unpack(">I4s", sub_header)
                        sub_type_str = sub_type.decode("latin1", errors="ignore")

                        if sub_size == 1:
                            sub_size = struct.unpack(">Q", f.read(8))[0]
                            sub_content_size = sub_size - 16
                        elif sub_size == 0:
                            sub_content_size = moov_end - f.tell()
                        else:
                            sub_content_size = sub_size - 8

                        if sub_content_size < 0:
                            break

                        if sub_type_str == "mvhd":
                            # mvhd atom found
                            mvhd_data = f.read(min(sub_content_size, 32))
                            if len(mvhd_data) >= 20:
                                version = mvhd_data[0]
                                if version == 1 and len(mvhd_data) >= 32:
                                    # 64-bit times: 1 byte ver + 3 byte flags + 8b create + 8b mod + 4b timescale + 8b duration
                                    timescale, duration = struct.unpack(">IQ", mvhd_data[20:32])
                                elif version == 0 and len(mvhd_data) >= 20:
                                    # 32-bit times: 1 byte ver + 3 byte flags + 4b create + 4b mod + 4b timescale + 4b duration
                                    timescale, duration = struct.unpack(">II", mvhd_data[12:20])
                                else:
                                    return -1.0

                                if timescale > 0:
                                    return float(duration) / float(timescale)
                            return -1.0
                        else:
                            # Skip to next sub-atom
                            f.seek(sub_content_size, os.SEEK_CUR)
                    return -1.0
                else:
                    # Skip to next atom
                    f.seek(content_size, os.SEEK_CUR)
    except Exception:
        pass
    return -1.0


def get_video_duration_mdls(file_path: str) -> float:
    """Read video duration using macOS native mdls tool if available."""
    if sys.platform != "darwin":
        return -1.0
    try:
        res = subprocess.run(
            ["/usr/bin/mdls", "-name", "kMDItemDurationSeconds", "-raw", file_path],
            capture_output=True,
            text=True,
            timeout=5
        )
        if res.returncode == 0:
            val = res.stdout.strip()
            if val and val != "(null)":
                return float(val)
    except Exception:
        pass
    return -1.0


def get_video_duration(file_path: str) -> float:
    """
    Universal video duration resolver:
    1. Pure Python parser (Universal, fast, works across Windows, Linux, macOS)
    2. macOS mdls fallback (if on macOS)
    """
    # 1. Pure Python parser (Primary across all OSes)
    dur = parse_mp4_duration(file_path)
    if dur > 0:
        return dur

    # 2. macOS native metadata helper
    if sys.platform == "darwin":
        dur = get_video_duration_mdls(file_path)
        if dur > 0:
            return dur

    return -1.0


def validate_media(input_path_str: str) -> dict:
    """
    Cross-platform media validator.
    Normalizes Windows (e.g. C:\\Users\\kiri\\...), POSIX (/home/kiri/...), and relative paths.
    """
    try:
        target = Path(input_path_str).expanduser().resolve()
    except Exception as e:
        return {
            "valid": False,
            "error": f"Invalid path syntax: {input_path_str} ({str(e)})"
        }

    if not target.exists():
        return {
            "valid": False,
            "error": f"Path does not exist: {input_path_str}"
        }

    # Case 1: Single file
    if target.is_file():
        suffix = target.suffix.lower()
        size_bytes = target.stat().st_size
        size_gb = round(size_bytes / (1024 ** 3), 3)

        if suffix in VIDEO_EXTENSIONS:
            if size_bytes > MAX_SIZE_BYTES:
                return {
                    "valid": False,
                    "type": "video",
                    "file": str(target),
                    "size_bytes": size_bytes,
                    "size_gb": size_gb,
                    "error": f"Video size ({size_gb} GB) exceeds limit of 5 GB."
                }

            duration = get_video_duration(str(target))
            duration_rounded = round(duration, 2) if duration > 0 else -1.0

            if duration <= 0:
                return {
                    "valid": False,
                    "type": "video",
                    "file": str(target),
                    "size_bytes": size_bytes,
                    "size_gb": size_gb,
                    "duration_seconds": -1,
                    "error": "Could not determine video duration. Ensure file is a valid MP4/MOV video."
                }

            if duration < MIN_VIDEO_DURATION:
                return {
                    "valid": False,
                    "type": "video",
                    "file": str(target),
                    "size_bytes": size_bytes,
                    "size_gb": size_gb,
                    "duration_seconds": duration_rounded,
                    "error": f"Video duration ({duration_rounded}s) is shorter than minimum 3 seconds."
                }

            if duration > MAX_VIDEO_DURATION:
                return {
                    "valid": False,
                    "type": "video",
                    "file": str(target),
                    "size_bytes": size_bytes,
                    "size_gb": size_gb,
                    "duration_seconds": duration_rounded,
                    "error": f"Video duration ({duration_rounded}s) exceeds maximum 3 minutes (180s)."
                }

            return {
                "valid": True,
                "type": "video",
                "file": str(target),
                "size_bytes": size_bytes,
                "size_gb": size_gb,
                "duration_seconds": duration_rounded,
                "message": f"Valid video scan: {duration_rounded}s, {size_gb} GB."
            }

        elif suffix in IMAGE_EXTENSIONS:
            return {
                "valid": False,
                "type": "photo",
                "file": str(target),
                "error": "Single photo provided. KIRI Engine requires 20-300 photos in a folder for photo reconstruction."
            }
        else:
            return {
                "valid": False,
                "error": f"Unsupported file type '{suffix}'. Supported formats: images ({', '.join(sorted(IMAGE_EXTENSIONS))}) or video ({', '.join(sorted(VIDEO_EXTENSIONS))})."
            }

    # Case 2: Directory of photos or video
    elif target.is_dir():
        photo_files = []
        video_files = []
        total_photo_bytes = 0

        for item in sorted(target.iterdir()):
            if item.is_file() and not item.name.startswith("."):
                ext = item.suffix.lower()
                if ext in IMAGE_EXTENSIONS:
                    photo_files.append(item)
                    total_photo_bytes += item.stat().st_size
                elif ext in VIDEO_EXTENSIONS:
                    video_files.append(item)

        # If directory contains a single video and no photos, treat as video input
        if len(video_files) == 1 and len(photo_files) == 0:
            return validate_media(str(video_files[0]))

        # Otherwise validate as photo set
        total_size_gb = round(total_photo_bytes / (1024 ** 3), 3)
        photo_count = len(photo_files)

        if photo_count < MIN_PHOTOS:
            return {
                "valid": False,
                "type": "photo",
                "directory": str(target),
                "count": photo_count,
                "size_bytes": total_photo_bytes,
                "size_gb": total_size_gb,
                "error": f"Found {photo_count} photos. KIRI Engine requires between 20 and 300 photos (minimum {MIN_PHOTOS})."
            }

        if photo_count > MAX_PHOTOS:
            return {
                "valid": False,
                "type": "photo",
                "directory": str(target),
                "count": photo_count,
                "size_bytes": total_photo_bytes,
                "size_gb": total_size_gb,
                "error": f"Found {photo_count} photos. Exceeds the limit of {MAX_PHOTOS} photos."
            }

        if total_photo_bytes > MAX_SIZE_BYTES:
            return {
                "valid": False,
                "type": "photo",
                "directory": str(target),
                "count": photo_count,
                "size_bytes": total_photo_bytes,
                "size_gb": total_size_gb,
                "error": f"Total photos size ({total_size_gb} GB) exceeds limit of 5 GB."
            }

        return {
            "valid": True,
            "type": "photo",
            "directory": str(target),
            "count": photo_count,
            "size_bytes": total_photo_bytes,
            "size_gb": total_size_gb,
            "message": f"Valid photo scan: {photo_count} photos, {total_size_gb} GB."
        }

    return {
        "valid": False,
        "error": f"Invalid path type: {input_path_str}"
    }


def main():
    if len(sys.argv) < 2:
        print(json.dumps({
            "valid": False,
            "error": "Usage: python validate_media.py <path-to-file-or-dir>"
        }, indent=2, ensure_ascii=False))
        sys.exit(1)

    result = validate_media(sys.argv[1])
    print(json.dumps(result, indent=2, ensure_ascii=False))
    sys.exit(0 if result.get("valid") else 1)


if __name__ == "__main__":
    main()
