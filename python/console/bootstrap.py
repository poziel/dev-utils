from __future__ import annotations

import importlib.util
from pathlib import Path
from urllib.error import URLError
from urllib.request import urlopen


REMOTE_BASE_URL = "https://raw.githubusercontent.com/poziel/dev-utils/main/python/console"
CACHE_DIR = Path.home() / ".cache" / "dev-utils" / "python" / "console"


def _cached_path(file_name: str) -> Path:
    return CACHE_DIR / file_name


def _read_local_version() -> str | None:
    version_path = _cached_path("version.txt")
    if not version_path.exists():
        return None

    return version_path.read_text(encoding="utf-8").strip()


def _read_remote_text(file_name: str) -> str:
    url = f"{REMOTE_BASE_URL}/{file_name}"
    with urlopen(url, timeout=10) as response:
        return response.read().decode("utf-8").strip()


def _download_file(file_name: str) -> None:
    url = f"{REMOTE_BASE_URL}/{file_name}"
    with urlopen(url, timeout=10) as response:
        _cached_path(file_name).write_bytes(response.read())


def _update_cache_if_needed() -> None:
    CACHE_DIR.mkdir(parents=True, exist_ok=True)

    try:
        remote_version = _read_remote_text("version.txt")
    except URLError as exc:
        if _cached_path("console.py").exists():
            return

        raise RuntimeError(
            "Console utility is not cached and could not be downloaded. "
            "Check your network connection and try again."
        ) from exc

    if _read_local_version() == remote_version:
        return

    _download_file("console.py")
    _download_file("version.txt")


def import_console():
    """Download, cache, and import the Console class."""
    _update_cache_if_needed()

    console_path = _cached_path("console.py")
    if not console_path.exists():
        raise RuntimeError(f"Cached console implementation was not found: {console_path}")

    spec = importlib.util.spec_from_file_location("dev_utils_console", console_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Could not import console implementation: {console_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.Console
