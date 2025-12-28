# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **project template** for implementing persistent, git-versioned memory in Claude Code sessions. It uses a two-layer memory system:
- **Layer 1: Raw Session Logs** (`.session_logs/`) - Complete temporal record of all work
- **Layer 2: Investigations** (`docs/investigations/`) - Curated hypothesis-driven research documentation

## Key Commands

```bash
# Install dependencies (required for semantic search)
pip install -r scripts/requirements.txt

# Archive current session (run at end of every session)
./scripts/archive-session.sh

# Convert JSONL session to markdown
python scripts/convert_session.py <input.jsonl> <output.md>

# Semantic search across investigations (when grep returns >20 results)
python scripts/semantic_filter.py "detailed query"

# Quick keyword search
rg -l "search_term" docs/investigations/
```

## Protocols

Protocol documents in `.claude/` guide session behavior:
- **STARTUP_PROTOCOL.md** - At session start: read last session log, check scratchpad, restore context
- **SESSION_END_PROTOCOL.md** - At session end: always run `archive-session.sh`, update scratchpad if needed
- **INVESTIGATION_PROTOCOL.md** - When to create investigation docs and how to structure them
- **RETRIEVAL_PROTOCOL.md** - How to search past work efficiently (grep first, semantic search if >20 results)

## Session Workflow

**At session start:**
```
User: "Read .claude/STARTUP_PROTOCOL.md and follow startup procedure"
```

**At session end:**
```bash
./scripts/archive-session.sh
git add .session_logs/
git commit -m "Session: [brief description]"
```

**After completing an investigation:**
```
User: "Create investigation doc for [topic] following the template"
```

## Architecture Notes

- Claude Code stores sessions at `~/.claude/projects/[encoded-path]/` where path separators become dashes
- `archive-session.sh` copies latest session to `.session_logs/YYYY-MM/DD_HHMM_raw.jsonl`
- Investigation docs link back to source sessions via frontmatter `source_sessions:` field
- Semantic search uses `sentence-transformers` with `BAAI/bge-large-en-v1.5` model (runs locally)

## Windows Users

WSL is required. Keep projects in WSL filesystem (`/home/user/projects/`) not mounted Windows drives (`/mnt/c/`).
