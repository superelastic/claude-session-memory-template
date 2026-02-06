## Session Memory

This project uses session memory for continuity between Claude Code sessions.

### How It Works

- **Session start**: Hooks auto-inject context from previous sessions
- **Session end**: Hooks archive the session for next time
- **Pending queue**: Sessions are captured immediately, summarized at next start

### Commands

- `/startup` — Manually load context from previous sessions
- `/session-end` — Manually create a session summary

### Search Past Work

```bash
# Keyword search
rg -l "search_term" sessions/ docs/

# Semantic search (requires: pip install -r scripts/requirements.txt)
python scripts/semantic_filter.py "your query"
```

### Key Directories

- `sessions/` — AI-generated session summaries
- `docs/investigations/` — Hypothesis-driven research records
- `docs/decisions/` — Architecture Decision Records
- `.session_logs/` — Raw session archives
