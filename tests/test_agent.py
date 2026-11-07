from helpers import env_value


def test_lists_agents_and_the_one_in_use(env):
    shop = env.project()
    r = env.roke("agent", cwd=shop)
    assert r.code == 0
    for agent in ("claude", "codex", "opencode"):
        assert agent in r.out
    assert "claude" in r.out.split("<- used here")[0].splitlines()[-1]
    assert "(default agent, roke.env)" in r.out


def test_use_in_the_project(env):
    shop = env.project()
    r = env.roke("agent", "use", "opencode", cwd=shop)
    assert r.code == 0, r.text
    assert env_value(env.project_env(), "ROKE_AGENT") == "opencode"
    assert "(this project)" in env.roke("agent", cwd=shop).out


def test_use_global_replaces_the_default(env):
    shop = env.project()
    assert env.roke("agent", "use", "codex", "--global", cwd=shop).code == 0
    roke_env = (env.config / "roke.env").read_text()
    assert roke_env.count("\nROKE_AGENT=") + roke_env.startswith("ROKE_AGENT=") == 1
    assert env_value(env.config / "roke.env", "ROKE_AGENT") == "codex"


def test_use_global_warns_when_the_project_has_its_own(env):
    shop = env.project()
    env.roke("agent", "use", "opencode", cwd=shop)
    r = env.roke("agent", "use", "codex", "--global", cwd=shop)
    assert "this project has its own agent" in r.text


def test_reset(env):
    shop = env.project()
    env.roke("agent", "use", "opencode", cwd=shop)
    assert env.roke("agent", "reset", cwd=shop).code == 0
    assert env_value(env.project_env(), "ROKE_AGENT") is None


def test_unknown_agent(env):
    r = env.roke("agent", "use", "nope", cwd=env.project())
    assert r.code != 0 and "unknown agent" in r.err


def test_run_needs_an_agent_when_several_are_installed(bare_env):
    bare_env.roke("init")
    r = bare_env.roke(cwd=bare_env.project())
    assert r.code != 0 and "choose a coding agent" in r.err


def test_run_uses_the_only_installed_agent(bare_env):
    bare_env.roke("init")
    bare_env.append(bare_env.config / "roke.env", 'ROKE_AGENTS="codex"\n')
    r = bare_env.roke(cwd=bare_env.project())
    assert r.code == 0, r.text
    assert r.last("run")["env"]["ROKE_AGENT"] == "codex"


def test_agent_option_overrides_everything(env):
    shop = env.project()
    env.roke("agent", "use", "opencode", cwd=shop)
    r = env.roke("--agent", "codex", cwd=shop)
    assert r.last("run")["env"]["ROKE_AGENT"] == "codex"


def test_project_agent_overrides_the_default(env):
    shop = env.project()
    env.roke("agent", "use", "opencode", cwd=shop)
    assert env.roke(cwd=shop).last("run")["env"]["ROKE_AGENT"] == "opencode"


def test_agent_not_in_the_image(env):
    shop = env.project()
    env.append(env.config / "roke.env", 'ROKE_AGENTS="claude"\n')
    assert "not in ROKE_AGENTS" in env.roke("agent", "use", "codex", cwd=shop).text
    r = env.roke("--agent", "codex", cwd=shop)
    assert r.code != 0 and "not in ROKE_AGENTS" in r.err
