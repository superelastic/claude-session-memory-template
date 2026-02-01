# Claude Code Session Memory Template

A project template for implementing persistent, git-versioned memory in Claude Code development sessions.

## What This Provides

- **Automatic session archiving** - Sessions captured on exit via hooks
- **Intelligent summarization** - Agent hook creates concise summaries at session start
- **Semantic search** - Find relevant past work with vector embeddings
- **Git-versioned memory** - Full project history travels with your code
- **Slash commands** - `/startup` and `/session-end` for manual control

## Quick Start

### Option A: Add to Existing Project

```bash
curl -fsSL https://raw.githubusercontent.com/superelastic/claude-session-memory-template/main/install.sh | bash
```

### Option B: Create New Project from Template

Click "Use this template" on GitHub, or:

```bash
git clone https://github.com/superelastic/claude-session-memory-template.git my-project
cd my-project
rm -rf .git && git init
```

### Enable Hooks

Copy the settings file to enable automatic session memory:

```bash
cp .claude/settings.json.example .claude/settings.local.json
```

### Install Dependencies (Optional, for semantic search)

```bash
pip install -r scripts/requirements.txt
```

### Start Working

```bash
claude  # or claude-code .
```

## How It Works

### The Pending Queue Pattern

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

1. **SessionEnd hook** runs `archive-session.sh`:
   - Copies session JSONL to `.session_logs/YYYY-MM/`
   - Converts to verbose markdown in `.session_logs/pending/`

2. **SessionStart agent hook** processes pending files:
   - Reads verbose transcripts
   - Creates focused summaries in `sessions/`
   - Deletes processed pending files
   - Restores context for new session

### Three-Layer Memory System

1. **Raw Session Logs** (`.session_logs/`) - Complete temporal record
2. **Session Summaries** (`sessions/`) - Concise AI-generated summaries
3. **Curated Documentation** (`docs/`) - Investigations, decisions, references

## What's Included

```
.claude/
├── commands/           # Slash commands (/startup, /session-end)
├── hooks/              # Shell hooks for session events
├── settings.json.example
└── *_PROTOCOL.md       # Behavior protocols

.session_logs/
├── pending/            # Sessions awaiting summarization
├── YYYY-MM/            # Archived sessions by month
└── .manifest           # Idempotency tracking

sessions/               # AI-generated session summaries
docs/                   # Curated documentation
scripts/                # Automation (archive, convert, search)
scratchpad.md           # Current work tracking
```

## Slash Commands

- `/startup` - Manually load context from previous sessions
- `/session-end` - Manually trigger session summary creation

## Semantic Search

Search across all session summaries and documentation:

```bash
# Auto-discovers sessions/, docs/, .session_logs/
python scripts/semantic_filter.py "your search query"

# With options
python scripts/semantic_filter.py "API authentication" --top-k 10 --snippets

# Search specific files
python scripts/semantic_filter.py "rate limiting" docs/investigations/*.md
```

Features:
- Document chunking (1000 chars, 200 overlap) for better retrieval
- Deduplication by document
- Uses `BAAI/bge-large-en-v1.5` embeddings (local, no API needed)

## System Requirements

### Windows Users: WSL Required

Claude Code stores sessions in Linux-style directories only accessible from WSL.

```powershell
# Install WSL
wsl --install
```

Keep projects in WSL filesystem:
```bash
✓ Good: /home/youruser/projects/my-project/
✗ Bad:  /mnt/c/Users/youruser/projects/my-project/
```

## Example Workflow

```bash
# Create project from template
git clone https://github.com/superelastic/claude-session-memory-template.git my-project
cd my-project
rm -rf .git && git init

# Enable hooks
cp .claude/settings.json.example .claude/settings.local.json

# Install semantic search (optional)
pip install -r scripts/requirements.txt

# Start working
claude

# ... work with Claude ...
# Sessions are automatically archived on exit
# Summaries created on next session start

# Search past work
python scripts/semantic_filter.py "how did we handle caching"
```

## Documentation

- [SETUP.md](SETUP.md) - Detailed setup guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - How the system works
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues
- [WORKFLOWS.md](WORKFLOWS.md) - Step-by-step workflows

## Contributing

Improvements and suggestions welcome! Please open an issue or PR.

## License

MIT License - Use freely in any project.
