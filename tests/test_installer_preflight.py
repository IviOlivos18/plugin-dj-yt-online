import json
import os
import subprocess
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "stop-previous-service.ps1"
POWERSHELL = Path(os.environ["SystemRoot"]) / "System32/WindowsPowerShell/v1.0/powershell.exe"


def run_preflight(port):
    return subprocess.run([str(POWERSHELL), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(SCRIPT), "-Port", str(port)], capture_output=True, text=True, timeout=20)


def serve(service_name):
    calls = []
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass
        def do_GET(self):
            body = json.dumps({"service": service_name}).encode() if self.path == "/api/health" else b'const shutdownToken = "fake_token_123"'
            self.send_response(200); self.send_header("Content-Type", "application/json" if self.path == "/api/health" else "text/html; charset=utf-8"); self.end_headers(); self.wfile.write(body)
        def do_POST(self):
            calls.append((self.path, self.headers.get("X-Shutdown-Token")))
            self.send_response(200); self.end_headers(); self.wfile.write(b"{}")
            threading.Thread(target=self.server.shutdown, daemon=True).start()
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True); thread.start()
    return server, thread, calls


def test_stops_identified_previous_service():
    server, thread, calls = serve("vdj-youtube-companion")
    try:
        result = run_preflight(server.server_port)
        assert result.returncode == 0, result.stderr
        assert calls == [("/api/shutdown", "fake_token_123")]
    finally:
        server.shutdown(); server.server_close(); thread.join(timeout=2)


def test_does_not_stop_an_unrelated_service():
    server, thread, calls = serve("unrelated-service")
    try:
        result = run_preflight(server.server_port)
        assert result.returncode != 0
        assert calls == []
    finally:
        server.shutdown(); server.server_close(); thread.join(timeout=2)
