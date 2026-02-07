# Session Memory Architecture

## Three-Layer Design

### Layer 1: Raw Session Logs (`.session_logs/`)

Complete audit trail of all Claude Code sessions.

```
.session_logs/
├── pending/           # Sessions awaiting summarization
├── YYYY-MM/           # Monthly archives
│   ├── DD_HHMM_raw.jsonl   # Original JSONL
│   └── DD_HHMM_raw.md      # Human-readable markdown
└── .manifest          # Tracks processed sessions (idempotency)
```

Source: Claude Code stores sessions at `~/.claude/projects/[encoded-path]/`
where `/home/user/project` becomes `-home-user-project`.

### Layer 2: Session Summaries (`sessions/`)

AI-generated 2-3 paragraph summaries created from pending files.

```
sessions/
├── 2025-01-15-api-integration.md
├── 2025-01-16-bug-fix-auth.md
└── 2025-01-17-refactor-db.md
```

### Layer 3: Curated Documentation (`docs/`)

Human-curated knowledge promoted from sessions:

```
docs/
├── investigations/    # Hypothesis-driven research (INVESTIGATION_TEMPLATE.md)
├── decisions/         # Architecture Decision Records (ADRs)
└── reference/         # Methodologies, gotchas, quick refs
```

## Pending Queue Pattern

```
SessionEnd  → archive-session.sh → .session_logs/pending/*.md
SessionStart → agent hook        → sessions/*.md + delete pending
```

Why separate capture from summarization:
- **SessionEnd hooks** may be interrupted — capture must be fast and simple
- **SessionStart agent hooks** have full agent capabilities for quality summaries
- **Manifest tracking** prevents duplicate processing
- **Pending files** survive abrupt session ends

## Semantic Search

Uses `sentence-transformers` with `BAAI/bge-large-en-v1.5` (fully local, no API calls).

- Document chunking: 1000 chars, 200 char overlap
- Auto-discovers: `sessions/`, `docs/`, `.session_logs/`
- Returns ranked results with relevance scores

## Search Strategy

| Project size | Approach |
|---|---|
| Small (<100 docs) | `rg` keyword search only |
| Medium (100-300) | `rg` first, semantic if >20 results |
| Large (300+) | Semantic search primary |

## Git Integration

All memory is git-versioned and travels with the project:
- `.session_logs/` — committed (full history)
- `sessions/` — committed (quick reference)
- `docs/` — committed (curated knowledge)
- `scratchpad.md` — committed (current state)
