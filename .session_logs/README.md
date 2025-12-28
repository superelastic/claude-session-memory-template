# Session Logs

This directory contains raw session archives from Claude Code, organized by year-month.

## Format

Files are named: `DD_HHMM_raw.jsonl` and `DD_HHMM_raw.md`

- **DD**: Day of month (01-31)
- **HHMM**: Hour and minute in 24-hour format
- **.jsonl**: Original JSONL from Claude Code (machine-readable)
- **.md**: Converted markdown (human-readable)

**Example:** `28_1430_raw.jsonl` = December 28, 2:30 PM session

## Purpose

These logs provide:
- Complete chronological record of all work
- Commands run and outputs received
- Experiments tried (including failures)
- Decisions made and rationale
- Full context for tracing back from investigation docs

## Directory Structure

```
.session_logs/
├── 2025-12/
│   ├── 25_1430_raw.jsonl
│   ├── 25_1430_raw.md
│   ├── 26_0900_raw.jsonl
│   ├── 26_0900_raw.md
│   └── ...
├── 2025-11/
│   └── ...
└── README.md (this file)
```

## Usage

### Archiving Sessions

At end of each Claude Code session:

```bash
./scripts/archive-session.sh
```

This copies the latest session from `~/.claude/projects/[encoded-path]/` to this directory.

### Reading Sessions

**View markdown (human-readable):**
```bash
cat .session_logs/2025-12/28_1430_raw.md
```

**View JSONL (machine-readable):**
```bash
cat .session_logs/2025-12/28_1430_raw.jsonl | jq '.'
```

### Finding Sessions

**List recent sessions:**
```bash
ls -lt .session_logs/*/*.md | head -10
```

**Search session content:**
```bash
rg "search_term" .session_logs/
```

**Find sessions from specific date:**
```bash
ls .session_logs/2025-12/28_*.md
```

## File Sizes

Typical sizes:
- Short session (30 min): 50-100KB
- Medium session (1-2 hours): 200-500KB
- Long session (3+ hours): 500KB-2MB

These are text files and compress well in git.

## Traceability

Investigation documents reference session logs in their frontmatter:

```yaml
---
source_sessions:
  - .session_logs/2025-12/28_1430_raw.jsonl
---
```

This creates bidirectional traceability between conclusions and the work that led to them.

## Retention

Session logs are:
- ✓ Git-versioned with project
- ✓ Permanent project history
- ✓ Valuable context for future work

Do NOT delete old sessions - they're your project's memory.

## Notes

- Always archive sessions, even "simple" ones
- Storage is cheap, lost context is expensive
- These logs make investigations traceable
- Future you will thank present you
