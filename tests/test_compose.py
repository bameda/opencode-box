"""Tests that need a real Docker Compose binary: the resolved configurations
of the example projects, and roke urls."""
import shutil
from pathlib import Path

import pytest

from conftest import REPO

EXAMPLES = sorted(p.name for p in (REPO / "examples" / "projects").iterdir() if p.is_dir())


@pytest.mark.parametrize("example", EXAMPLES)
@pytest.mark.parametrize("agent", ["claude", "codex", "opencode"])
def test_example_projects_resolve(env, compose, example, agent):
    shutil.copytree(REPO / "examples" / "projects" / example, env.config / "projects" / example)
    project = env.project(example)
    r = env.roke("urls", "--agent", agent, cwd=project, env={"FAKE_REAL_COMPOSE": compose})
    assert r.code == 0, r.text
    assert "Reach from inside the box" in r.out


def test_urls(env, compose):
    shop = env.project()
    env.write_project_env("ROKE_SERVICES=postgres,mailpit\nPOSTGRES_DB=shop\nMAILPIT_UI_PORT=18025\n")
    r = env.roke("urls", "-p", "5173", cwd=shop, env={"FAKE_REAL_COMPOSE": compose})
    assert r.code == 0, r.text
    assert "http://127.0.0.1:5173 (box port 5173)" in r.out
    assert "mailpit      http://127.0.0.1:18025" in r.out
    assert "DATABASE_URL=postgres://dev:dev@postgres:5432/shop" in r.out
    assert "mailpit:1025 · mailpit:8025" in r.out


def test_urls_needs_the_image(env):
    r = env.roke("urls", cwd=env.project(), env={"FAKE_NO_IMAGE": "1"})
    assert r.code != 0 and "roke build" in r.err
