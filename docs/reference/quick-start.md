# Session Memory Plugin — Quick Start

## 1. Add the plugin marketplace (once)

```bash
claude  # then from within Claude Code:
/plugin marketplace add https://github.com/superelastic/claude-session-memory-template
```

## 2. Install the plugin (once per machine)

```
/plugin install session-memory@session-memory
```

## 3. Initialize a project

Open Claude Code in your project directory and run:

```
/session-memory:setup
```

This creates the directory structure (`sessions/`, `docs/`, `.session_logs/`, `scratchpad.md`) and appends a session-memory section to your project's `CLAUDE.md`. Commit the result.

## 4. Use it (no effort required)

Everything is automatic after setup:

- **End a session** — the SessionEnd hook archives your JSONL transcript to `.session_logs/pending/` as markdown
- **Start a new session** — the SessionStart hook catches any missed archives, then the agent hook summarizes pending files into `sessions/` and restores context from the last session + scratchpad
- **Search past work** — `/session-memory:search <query>` or just ask "how did we handle X?" and the skill kicks in

## 5. What gets created in your project

```
scratchpad.md              Current TODOs and working context
sessions/                  AI-generated session summaries
docs/investigations/       Multi-session research records
docs/decisions/            Architecture decision records
docs/reference/            Reference material
.session_logs/             Raw archives + pending queue
```

All of it is git-versioned — it travels with the repo and is available to anyone who clones it.

## Key things to know

- **You don't need to run any commands** — hooks handle the archive/restore cycle automatically
- If a session closes abruptly, the next SessionStart catches up (no data loss)
- The MCP server provides `search_sessions` and `semantic_search` tools for richer queries
- Update `scratchpad.md` before ending a session to leave breadcrumbs for next time
