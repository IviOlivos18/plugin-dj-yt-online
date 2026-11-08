import functools
import http.server
import os
import subprocess
import threading
import zipfile
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "archive-download.ps1"
PS = Path(os.environ["SystemRoot"]) / "System32/WindowsPowerShell/v1.0/powershell.exe"


def test_corrupt_cached_archive_is_replaced(tmp_path):
    served = tmp_path / "served"
    served.mkdir()
    archive = served / "package.zip"
    with zipfile.ZipFile(archive, "w") as z:
        z.writestr("ffmpeg/bin/ffmpeg.exe", b"sample")
    target = tmp_path / "cached.zip"
    target.write_bytes(b"incomplete archive")
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(served))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    try:
        cmd = ". '%s'; Get-VerifiedZip 'http://127.0.0.1:%s/package.zip' '%s' '*/bin/ffmpeg.exe'" % (SCRIPT, server.server_port, target)
        result = subprocess.run([str(PS), "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd], capture_output=True, text=True, timeout=25)
        assert result.returncode == 0, result.stderr
        with zipfile.ZipFile(target) as z:
            assert z.read("ffmpeg/bin/ffmpeg.exe") == b"sample"
        assert not list(tmp_path.glob("*.part"))
    finally:
        server.shutdown(); server.server_close(); thread.join(timeout=2)


def test_invalid_download_keeps_existing_file(tmp_path):
    served = tmp_path / "served"
    served.mkdir()
    (served / "bad.zip").write_bytes(b"bad data")
    target = tmp_path / "cached.zip"
    target.write_bytes(b"old incomplete data")
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=str(served))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
    try:
        cmd = ". '%s'; Get-VerifiedZip 'http://127.0.0.1:%s/bad.zip' '%s' '*/bin/ffmpeg.exe'" % (SCRIPT, server.server_port, target)
        result = subprocess.run([str(PS), "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", cmd], capture_output=True, text=True, timeout=25)
        assert result.returncode != 0
        assert target.read_bytes() == b"old incomplete data"
        assert not list(tmp_path.glob("*.part"))
    finally:
        server.shutdown(); server.server_close(); thread.join(timeout=2)
