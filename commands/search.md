---
description: Search past sessions and documentation using semantic or keyword search
argument-hint: <query>
disable-model-invocation: true
---

# Session Memory Search

Search past sessions and documentation for relevant context.

Semantic search script: !`echo ${CLAUDE_PLUGIN_ROOT}/scripts/semantic_filter.py`

## Strategy

1. **Start with keyword search** (fast, precise):
   ```bash
   rg -l "$ARGUMENTS" sessions/ docs/ .session_logs/
   ```

2. **If too many results (>20) or keywords are ambiguous**, use the semantic search script shown above with the query as argument

3. Read the most relevant results and summarize findings for the user

## Scoping

- `sessions/` — AI-generated session summaries (search here first)
- `docs/investigations/` — Hypothesis-driven research
- `docs/decisions/` — Architecture Decision Records
- `docs/reference/` — Methodologies and quick refs
- `.session_logs/` — Full raw session archives (last resort)
