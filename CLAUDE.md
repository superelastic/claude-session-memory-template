# CLAUDE.md

This file provides guidance to Claude Code when working on this repository.

## Project Overview

This is a **Claude Code plugin** (`session-memory`) that provides persistent, git-versioned memory across sessions. It installs into host projects via `/plugin add`.

## Plugin Structure

```
.claude-plugin/plugin.json    Plugin manifest
skills/session-memory/         SKILL.md + references/ (progressive disclosure)
commands/                      setup, startup, session-end, search
hooks/hooks.json               SessionStart + SessionEnd hooks
scripts/                       Archive, convert, search, MCP server, hook entry points
.mcp.json                      MCP server config
```

## Key Architecture

### Three-Layer Memory (created in host projects)

1. **Raw Session Logs** (`.session_logs/`) — Complete temporal record
2. **Session Summaries** (`sessions/`) — Concise AI-generated summaries
3. **Curated Documentation** (`docs/`) — Investigations, decisions, references

### Pending Queue Pattern

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

### Environment Variables

- `CLAUDE_PLUGIN_ROOT` — Resolves in hooks.json and .mcp.json to this plugin's install path
- `CLAUDE_PROJECT_DIR` — The host project directory (where sessions/docs live)
- Neither resolves in SKILL.md or command markdown body — use `!`command`` dynamic injection for paths in commands

## Scripts

- `scripts/archive-session.sh` — Archives session JSONL to pending (uses `SCRIPT_DIR` for sibling script resolution)
- `scripts/convert_session.py` — JSONL to markdown conversion
- `scripts/semantic_filter.py` — Embedding search (uses `CLAUDE_PROJECT_DIR` for project root)
- `scripts/mcp_server.py` — FastMCP server with 4 tools (search, semantic search, read, list)
- `scripts/run-mcp-server.sh` — MCP wrapper that auto-creates venv and installs `mcp` package
- `scripts/session-start-hook.sh` / `scripts/session-end-hook.sh` — Hook entry points

## Development

```bash
# Test plugin loading
claude --plugin-dir . -p "what skills do you have?"

# Test hooks
CLAUDE_PROJECT_DIR=/tmp/test-project CLAUDE_PLUGIN_ROOT=$(pwd) bash scripts/session-end-hook.sh
CLAUDE_PROJECT_DIR=/tmp/test-project bash scripts/session-start-hook.sh

# Test MCP server
CLAUDE_PROJECT_DIR=$(pwd) .venv/bin/python scripts/mcp_server.py

# Install MCP dependency
python -m venv .venv && .venv/bin/pip install mcp
```

## Notes

- Semantic search uses `BAAI/bge-large-en-v1.5` locally (no API calls)
- MCP venv is auto-created by `run-mcp-server.sh` on first run
- `docs/claude-session-memory.md` is the CLAUDE.md snippet injected into host projects by `/session-memory:setup`
