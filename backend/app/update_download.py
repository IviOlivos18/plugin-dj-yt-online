"""Download verified release packages without executing them."""
import hashlib
import os
import re
import tempfile
from pathlib import Path
from urllib.parse import urlparse

import httpx

MAX_BYTES = 250 * 1024 * 1024


def _check_url(url: str, repository: str) -> None:
    parsed = urlparse(url)
    prefix = "/" + repository + "/releases/download/"
    if parsed.scheme != "https" or parsed.netloc != "github.com" or not parsed.path.startswith(prefix) or parsed.query or parsed.fragment:
        raise ValueError("Untrusted update URL")


async def download_verified(url: str, digest: str, repository: str, destination: Path) -> Path:
    _check_url(url, repository)
    if not re.fullmatch(r"sha256:[0-9a-f]{64}", digest or ""):
        raise ValueError("Missing or invalid update digest")
    destination.mkdir(parents=True, exist_ok=True)
    final = destination / (digest[7:] + ".exe")
    if final.is_file():
        existing = hashlib.sha256()
        with final.open("rb") as stream:
            for chunk in iter(lambda: stream.read(1024 * 1024), b""):
                existing.update(chunk)
        if existing.hexdigest() == digest[7:]:
            return final
    fd, temp_name = tempfile.mkstemp(prefix="download-", suffix=".partial", dir=destination)
    temp_path = Path(temp_name)
    try:
        h = hashlib.sha256()
        size = 0
        with os.fdopen(fd, "wb") as output:
            async with httpx.AsyncClient(follow_redirects=True, timeout=30.0) as client:
                async with client.stream("GET", url, headers={"User-Agent": "Plugin-Online-Updater"}) as response:
                    response.raise_for_status()
                    if response.url.scheme != "https":
                        raise ValueError("Insecure download redirect")
                    async for chunk in response.aiter_bytes():
                        size += len(chunk)
                        if size > MAX_BYTES:
                            raise ValueError("Update exceeds size limit")
                        h.update(chunk)
                        output.write(chunk)
        if h.hexdigest() != digest[7:]:
            raise ValueError("Update checksum mismatch")
        os.replace(temp_path, final)
        return final
    finally:
        temp_path.unlink(missing_ok=True)
