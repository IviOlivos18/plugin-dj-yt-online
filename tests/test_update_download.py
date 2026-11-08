import hashlib

import httpx
import pytest

from backend.app.update_download import download_verified


@pytest.mark.asyncio
async def test_download_verifies_and_reuses_cached_package(monkeypatch, tmp_path):
    content = b"test release bytes"
    expected = "sha256:" + hashlib.sha256(content).hexdigest()
    requests = []
    def handler(request):
        requests.append(request)
        return httpx.Response(200, content=content)
    real_client = httpx.AsyncClient
    monkeypatch.setattr("backend.app.update_download.httpx.AsyncClient", lambda **kwargs: real_client(transport=httpx.MockTransport(handler), **kwargs))
    url = "https://github.com/owner/repo/releases/download/v1.0.0/installer.exe"
    result = await download_verified(url, expected, "owner/repo", tmp_path)
    assert result.read_bytes() == content
    assert await download_verified(url, expected, "owner/repo", tmp_path) == result
    assert len(requests) == 1


@pytest.mark.asyncio
async def test_download_rejects_incorrect_checksum_and_cleans_partial(monkeypatch, tmp_path):
    def handler(request):
        return httpx.Response(200, content=b"different bytes")
    real_client = httpx.AsyncClient
    monkeypatch.setattr("backend.app.update_download.httpx.AsyncClient", lambda **kwargs: real_client(transport=httpx.MockTransport(handler), **kwargs))
    with pytest.raises(ValueError, match="checksum mismatch"):
        await download_verified("https://github.com/owner/repo/releases/download/v1.0.0/installer.exe", "sha256:" + "0" * 64, "owner/repo", tmp_path)
    assert not list(tmp_path.iterdir())


@pytest.mark.asyncio
async def test_download_rejects_other_hosts(tmp_path):
    with pytest.raises(ValueError, match="Untrusted"):
        await download_verified("https://example.com/payload.exe", "sha256:" + "0" * 64, "owner/repo", tmp_path)


@pytest.mark.asyncio
async def test_background_checker_downloads_only_new_verified_release(monkeypatch, tmp_path):
    import asyncio
    import importlib
    main = importlib.import_module("backend.app.main")
    called = asyncio.Event()
    async def fake_check():
        return {"updateAvailable": True, "downloadUrl": "https://github.com/owner/repo/releases/download/v1.0.0/installer.exe", "sha256": "sha256:" + "a" * 64, "latestVersion": "1.0.0"}
    async def fake_download(url, digest, repo, destination):
        assert repo == "owner/repo"
        assert destination == tmp_path / "updates"
        called.set()
    monkeypatch.setattr(main.update_checker, "check", fake_check)
    monkeypatch.setattr(main, "download_verified", fake_download)
    monkeypatch.setattr(main.settings, "github_repository", "owner/repo")
    monkeypatch.setattr(main.settings, "data_dir", tmp_path)
    task = asyncio.create_task(main._prepare_update_once())
    await asyncio.wait_for(called.wait(), timeout=2)
    await asyncio.wait_for(task, timeout=2)
    assert main.update_state["status"] == "ready"


def test_browser_origins_cannot_trigger_update():
    from fastapi.testclient import TestClient
    from backend.app.main import app
    with TestClient(app) as client:
        response = client.post("/api/update/virtualdj-open", headers={"Origin": "https://example.com"})
    assert response.status_code == 403


def test_lifespan_does_not_check_without_virtualdj(monkeypatch):
    from fastapi.testclient import TestClient
    import importlib
    main = importlib.import_module("backend.app.main")
    async def unexpected():
        raise AssertionError("Update should not be checked at service startup")
    monkeypatch.setattr(main, "_prepare_update_once", unexpected)
    with TestClient(main.app) as client:
        assert client.get("/api/update/state").status_code == 200


@pytest.mark.asyncio
async def test_check_trigger_clears_old_current_status(monkeypatch):
    import asyncio
    import importlib
    main = importlib.import_module("backend.app.main")
    gate = asyncio.Event()
    class FakeClient:
        host = "127.0.0.1"
    class FakeRequest:
        client = FakeClient()
        headers = {}
    async def pending_check():
        await gate.wait()
    monkeypatch.setattr(main, "_prepare_update_once", pending_check)
    monkeypatch.setattr(main, "update_task", None)
    main.update_state.update(status="current", version="0.1.2", message=None)
    result = await main.update_virtualdj_open(FakeRequest())
    assert result == {"accepted": True}
    assert main.update_state["status"] == "checking"
    assert main.update_state["version"] is None
    gate.set()
    await main.update_task
