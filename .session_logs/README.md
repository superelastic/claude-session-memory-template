# Session Logs

This directory contains raw session archives from Claude Code, organized by year-month.

## Directory Structure

```
.session_logs/
├── .manifest              # Tracks processed session UUIDs (idempotency)
├── pending/               # Sessions awaiting summarization
│   └── 20250128_1430_abc12345.md
├── 2025-12/               # Archived sessions by month
│   ├── 20251228_1430_abc12345.jsonl
│   └── 20251228_1430_abc12345.md
└── README.md (this file)
```

## File Naming

Files are named: `YYYYMMDD_HHMM_SESSIONID.{jsonl,md}`

- **YYYYMMDD**: Date (year, month, day)
- **HHMM**: Time in 24-hour format
- **SESSIONID**: First 8 characters of session UUID
- **.jsonl**: Original JSONL from Claude Code (machine-readable)
- **.md**: Converted markdown (human-readable)

**Example:** `20251228_1430_abc12345.jsonl` = December 28, 2025, 2:30 PM session

## The Pending Queue Pattern

```
SessionEnd → archive-session.sh → pending/*.md (verbose transcript)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

### How It Works

1. **SessionEnd hook** runs `archive-session.sh`:
   - Copies JSONL to `.session_logs/YYYY-MM/`
   - Converts to markdown in `.session_logs/pending/`
   - Records session UUID in `.manifest`

2. **SessionStart agent hook** processes pending:
   - Reads verbose transcripts from `pending/`
   - Creates focused summaries in `sessions/`
   - Deletes processed pending files

### Why This Pattern?

- **Immediate capture**: Sessions are archived the moment they end (command hook)
- **Intelligent summarization**: Agent creates meaningful summaries (agent hook)
- **Idempotency**: Manifest prevents duplicate processing
- **Resume safety**: Pending files survive if session ends abruptly

## Usage

### Archiving Sessions (Manual)

```bash
./scripts/archive-session.sh
```

This runs automatically on SessionEnd, but you can run it manually.

### Reading Sessions

**View recent session transcripts:**
```bash
ls -t .session_logs/*/*.md | head -5
```

**View session summaries:**
```bash
ls sessions/
```

**Search session content:**
```bash
rg "search_term" .session_logs/ sessions/
```

## Idempotency

The `.manifest` file tracks which sessions have been processed:
- Each line contains a session UUID
- `archive-session.sh` checks this before processing
- Prevents duplicate archives when `/resume` is used

## File Sizes

Typical sizes:
- Short session (30 min): 50-100KB JSONL, 10-20KB markdown
- Medium session (1-2 hours): 200-500KB JSONL, 30-80KB markdown
- Session summary: 1-3KB

## Retention

Session logs are:
- Git-versioned with project (markdown files)
- JSONL files are gitignored (large, redundant with markdown)
- Permanent project history

Do NOT delete old sessions - they're your project's memory.
