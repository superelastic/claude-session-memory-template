# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **project template** for implementing persistent, git-versioned memory in Claude Code sessions. It uses a layered memory system:

- **Layer 1: Raw Session Logs** (`.session_logs/`) - Complete temporal record of all work
- **Layer 2: Session Summaries** (`sessions/`) - Concise summaries created by agent hook
- **Layer 3: Curated Documentation** (`docs/`) - Organized knowledge:
  - `investigations/` - Hypothesis-driven research with experiments and conclusions
  - `decisions/` - Architecture Decision Records (ADRs)
  - `reference/` - Methodologies, gotchas, quick references

## Session Memory Architecture

### The Pending Queue Pattern

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

This ensures:
1. Sessions are captured immediately when they end (command hook)
2. Summaries are created intelligently at next start (agent hook)
3. No duplicate processing (pending files deleted after summary)

### Hooks Configuration

Copy `.claude/settings.json.example` to `.claude/settings.local.json` to enable:
- **SessionStart**: Command hook injects context + agent hook summarizes pending
- **SessionEnd**: Command hook runs archive script

## Key Commands

```bash
# Install dependencies (required for semantic search)
pip install -r scripts/requirements.txt

# Archive current session (runs automatically on SessionEnd)
./scripts/archive-session.sh

# Semantic search (auto-discovers sessions/, docs/, .session_logs/)
python scripts/semantic_filter.py "your query"

# Quick keyword search
rg -l "search_term" sessions/ docs/
```

## Slash Commands

- `/startup` - Manually load context from previous sessions
- `/session-end` - Manually create session summary (alternative to automatic hook)

## Session Workflow

**Automatic (with hooks enabled):**
1. SessionEnd hook archives session to `pending/`
2. Next SessionStart agent hook creates summary in `sessions/`
3. Context is automatically restored

**Manual:**
```bash
# At session end
./scripts/archive-session.sh

# At session start
# Use /startup command or read sessions/ manually
```

## Protocols

Protocol documents in `.claude/` guide session behavior:
- **STARTUP_PROTOCOL.md** - Process pending summaries, restore context
- **SESSION_END_PROTOCOL.md** - Archive sessions, update scratchpad
- **INVESTIGATION_PROTOCOL.md** - When and how to create investigation docs
- **RETRIEVAL_PROTOCOL.md** - Search strategies (grep first, semantic if >20 results)

## Architecture Notes

- Claude Code stores sessions at `~/.claude/projects/[encoded-path]/`
- Path encoding: `/home/user/project` becomes `-home-user-project`
- Semantic search uses `sentence-transformers` with `BAAI/bge-large-en-v1.5` (local)
- Document chunking (1000 chars, 200 overlap) improves retrieval accuracy

## Windows Users

WSL is required. Keep projects in WSL filesystem (`/home/user/projects/`) not mounted Windows drives (`/mnt/c/`).
