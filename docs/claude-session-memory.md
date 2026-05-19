## Session Memory

This project uses the **session-memory** plugin for continuity between Claude Code sessions. All memory is git-versioned and travels with the repo.

### How It Works

- **Automatic**: Hooks archive sessions on end and restore context on start
- **Pending queue**: Sessions captured immediately, summarized intelligently at next start
- **Searchable**: Past work is searchable via MCP tools or keyword search

### Session-Start Rule

If the startup-hook context lists pending session summaries, **process
them before responding to the user's first substantive task** (see the
session-memory skill for the per-file procedure). For casual first
messages, curate first then answer; for substantial tasks, ask once
whether to curate first or defer — do not silently skip.

### Key Directories

- `sessions/` — AI-generated session summaries
- `docs/investigations/` — Hypothesis-driven research records
- `docs/decisions/` — Architecture Decision Records
- `docs/reference/` — Methodologies and quick references
- `.session_logs/` — Raw session archives
- `scratchpad.md` — Current work tracking and TODOs

### Commands

- `/session-memory:startup` — Manually load context from previous sessions
- `/session-memory:session-end` — Manually archive and summarize current session
- `/session-memory:search <query>` — Search past sessions and documentation
