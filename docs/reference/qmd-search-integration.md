# qmd Search Integration Options

*Analysis of whether/how to adopt [tobi/qmd](https://github.com/tobi/qmd) patterns into the session-memory plugin.*

---

## Background: Current Search Weaknesses

The plugin's current `search_sessions` MCP tool uses a naive term-counting approach: it scans every session file, counts keyword occurrences, and ranks by frequency. Problems:

- No stemming — "search" and "searching" are different terms
- No relevance ranking beyond raw counts
- No excerpt/snippet extraction
- Semantic search (`semantic_search`) requires `sentence-transformers` + a local model download (~1 GB), which is too heavy for most users
- Both tools rebuild from scratch on every call; no persistent index

---

## What qmd Offers

[qmd](https://github.com/tobi/qmd) is a CLI tool and MCP server for document search. Relevant capabilities:

| Feature | Detail |
|---------|--------|
| FTS5 BM25 | SQLite full-text search with BM25 ranking — fast, no extra deps |
| SQLite-vec embeddings | Vector search via `sqlite-vec` extension — lighter than sentence-transformers |
| LLM reranker | Optional query expansion and cross-encoder reranking |
| Reciprocal Rank Fusion (RRF) | Combines BM25 + vector scores into a single ranked list |
| Built-in MCP server | `qmd serve` exposes a `query` tool directly to Claude |
| Project maturity | Active, well-documented, single binary install |

---

## Recommendation: Two-Track Adoption

### Track 1 — Optional qmd Integration (zero new plugin code)

**Approach:** Detect qmd at setup time, register the session-memory collection, and update the skill to prefer `qmd query` when available.

**How it would work:**

1. In `commands/setup.md`, after creating the directory structure, add:
   ```bash
   if command -v qmd &>/dev/null; then
     qmd collection add session-memory sessions/ docs/
     qmd embed session-memory
     echo "qmd collection registered — semantic search available"
   else
     echo "Tip: install qmd for better search (https://github.com/tobi/qmd)"
   fi
   ```

2. In `skills/session-memory/SKILL.md`, update the "Searching Past Work" section:
   > If `which qmd` succeeds, prefer `qmd query session-memory "<query>"` for BM25 + vector + reranked results. Otherwise fall through to the built-in `search_sessions` / `semantic_search` MCP tools.

3. In `docs/claude-session-memory.md` (the CLAUDE.md snippet injected into host projects), add a "Search Upgrade (optional)" section pointing to qmd with install/re-run instructions.

**Pros:** No new plugin code. qmd handles indexing, re-embedding, and MCP serving. Degrades gracefully when qmd isn't installed.

**Cons:** Requires user to install qmd separately. Collection must be re-registered after plugin setup. Users without qmd get no improvement.

---

### Track 2 — Built-in SQLite FTS5 BM25 (no new dependency)

**Approach:** Replace the naive term-counting in `scripts/mcp_server.py` with SQLite FTS5 using only the stdlib `sqlite3` module.

**How it would work:**

- Index lives at `.session_logs/search.db` (add to `.gitignore`)
- Index is rebuilt automatically when `.session_logs/.manifest` mtime changes (lazy rebuild on first query after new sessions appear)
- Use `fts5` with Porter stemmer (`tokenize="porter ascii"`)
- Use `bm25()` for ranking and `snippet()` for context extraction

**Key implementation sketch for `mcp_server.py`:**

```python
import sqlite3, hashlib, os, time
from pathlib import Path

DB_PATH = PROJECT_DIR / ".session_logs" / "search.db"
MANIFEST_PATH = PROJECT_DIR / ".session_logs" / ".manifest"

def _needs_rebuild(db: sqlite3.Connection) -> bool:
    manifest_mtime = MANIFEST_PATH.stat().st_mtime if MANIFEST_PATH.exists() else 0
    row = db.execute("SELECT value FROM meta WHERE key='manifest_mtime'").fetchone()
    return row is None or float(row[0]) < manifest_mtime

def _build_fts_index(db: sqlite3.Connection):
    db.execute("DROP TABLE IF EXISTS sessions_fts")
    db.execute("""CREATE VIRTUAL TABLE sessions_fts USING fts5(
        path UNINDEXED, title, body,
        tokenize='porter ascii'
    )""")
    # ... insert session files ...
    manifest_mtime = MANIFEST_PATH.stat().st_mtime if MANIFEST_PATH.exists() else 0
    db.execute("INSERT OR REPLACE INTO meta VALUES ('manifest_mtime', ?)", (manifest_mtime,))
    db.commit()

def search_sessions(query: str, top_k: int = 5):
    db = sqlite3.connect(DB_PATH)
    if _needs_rebuild(db):
        _build_fts_index(db)
    rows = db.execute("""
        SELECT path, snippet(sessions_fts, 2, '[', ']', '...', 32)
        FROM sessions_fts
        WHERE sessions_fts MATCH ?
        ORDER BY bm25(sessions_fts)
        LIMIT ?
    """, (query, top_k)).fetchall()
    return [{"path": r[0], "snippet": r[1]} for r in rows]
```

**Pros:** No new dependencies (`sqlite3` is stdlib). Persistent index. Real BM25 with stemming. Snippet extraction. Works for all users immediately.

**Cons:** More plugin code to maintain. FTS5 syntax errors need a fallback (keep old linear scan as `_search_fallback`). Index file needs to be in `.gitignore`.

---

## What NOT to Adopt

- **LLM reranker / query expansion**: Too heavy for routine session search. Adds latency and API cost.
- **Hard dependency on qmd**: Would break setup for users without qmd installed. Always treat as optional.
- **sqlite-vec embeddings as a built-in**: The extension is not bundled with Python's `sqlite3`. Would require either a native binary or a pip dep — not worth it when `sentence-transformers` already handles this for users who want semantic search.

---

## If/When Implementing

### Track 1 (qmd optional integration)
Files to change:
- `commands/setup.md` — add qmd detection + collection registration step
- `skills/session-memory/SKILL.md` — add qmd-first search note
- `docs/claude-session-memory.md` — add optional search upgrade section
- `.gitignore` in host project template — no change needed (qmd manages its own index)

### Track 2 (SQLite FTS5 built-in)
Files to change:
- `scripts/mcp_server.py` — replace `search_sessions` with FTS5 implementation; add `_build_fts_index`, `_needs_rebuild`, `_get_or_build_index`, `_search_fallback` helpers
- `docs/claude-session-memory.md` — add `.session_logs/search.db` to the `.gitignore` stanza in the CLAUDE.md snippet

The two tracks are independent and can be implemented in either order.
