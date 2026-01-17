# Claude Code Session Memory Template

A project template for implementing persistent, git-versioned memory in Claude Code development sessions.

## What This Provides

- ✅ **Automatic session archiving** - Preserve complete Claude Code sessions with your project
- ✅ **Investigation documentation** - Structured hypothesis-driven research documentation
- ✅ **Semantic search** - Find relevant past work across all investigations
- ✅ **Git-versioned memory** - Full project history travels with your code
- ✅ **Context restoration** - Claude can restore context from previous sessions

## Quick Start

### Option A: Add to Existing Project

Run this from your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/superelastic/claude-session-memory-template/main/install.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/superelastic/claude-session-memory-template/main/install.sh
chmod +x install.sh
./install.sh
```

### Option B: Create New Project from Template

Click "Use this template" on GitHub, or:

```bash
git clone https://github.com/superelastic/claude-session-memory-template.git my-project
cd my-project
rm -rf .git  # Remove template's git history
git init     # Start fresh
```

### 2. Install Dependencies (Optional)

```bash
pip install -r scripts/requirements.txt
```

### 3. Start Working

```bash
claude-code .
```

### 4. At Session End (Always)

```bash
./scripts/archive-session.sh
git add .session_logs/
git commit -m "Session: [brief description]"
```

### 5. After Completing Investigation

```
You: "Create investigation doc for [topic] following the template"

Claude: [creates docs/investigations/topic.md]
```

```bash
git add docs/investigations/
git commit -m "Investigation: [topic] - [key finding]"
```

## What's Included

- **`.session_logs/`** - Raw session archives from Claude Code
- **`docs/investigations/`** - Structured investigation documentation
- **`.claude/`** - Protocol documents that guide Claude's behavior
- **`scripts/`** - Automation scripts (archive, convert, search)
- **`scratchpad.md`** - Current work tracking

## System Requirements

### Windows Users: WSL Required

This template requires WSL (Windows Subsystem for Linux) when using Claude Code on Windows.

**Why:** Claude Code stores sessions in Linux-style directories only accessible from WSL:
```
~/.claude/projects/[encoded-path]/
```

**Setup WSL:**
```powershell
# In PowerShell (Admin)
wsl --install
```

**Keep projects in WSL filesystem** (not `/mnt/c/`):
```bash
✓ Good: /home/youruser/projects/my-project/
✗ Bad:  /mnt/c/Users/youruser/projects/my-project/
```

## How It Works

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed explanation.

**Two-layer memory system:**

1. **Layer 1: Raw Session Logs** (`.session_logs/`)
   - Complete temporal record of all work
   - Copied from Claude's `~/.claude/projects/[encoded-path]/`
   - Git-versioned with project

2. **Layer 2: Investigations** (`docs/investigations/`)
   - Curated findings: Hypothesis → Experiments → Conclusions
   - Created by Claude after completing investigations
   - Includes links back to source sessions

**On-demand semantic search:**
- Only when grep returns too many results (>20 files)
- Uses local sentence-transformers model
- No external dependencies or databases

## Documentation

- [SETUP.md](SETUP.md) - Detailed setup and usage guide
- [ARCHITECTURE.md](ARCHITECTURE.md) - How the system works
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [WORKFLOWS.md](WORKFLOWS.md) - Step-by-step workflows for different scenarios

## Protocol Documents

Located in `.claude/`, these guide Claude's behavior:

- `STARTUP_PROTOCOL.md` - What Claude does at session start
- `SESSION_END_PROTOCOL.md` - Session archiving procedure
- `INVESTIGATION_PROTOCOL.md` - Creating investigation documents
- `RETRIEVAL_PROTOCOL.md` - Searching past work

## Scripts

Located in `scripts/`:

- `archive-session.sh` - Copy latest Claude session to project
- `convert_session.py` - Convert JSONL sessions to readable markdown
- `semantic_filter.py` - Semantic search over investigations

## Example Workflow

```bash
# Start new project from template
git clone https://github.com/superelastic/claude-session-memory-template.git theta-data-analysis
cd theta-data-analysis

# Install dependencies
pip install -r scripts/requirements.txt

# Start working with Claude Code
claude-code .

# During work: Claude follows protocols automatically
# - Reads last session at startup
# - Checks scratchpad for pending items
# - Restores context

# At session end
./scripts/archive-session.sh

# If investigation completed
# Prompt Claude: "Create investigation doc for rate limiting"

# Commit
git add .session_logs/ docs/investigations/
git commit -m "Investigation: API rate limiting analysis"

# Later: Search past work
python scripts/semantic_filter.py "how did we handle authentication"
```

## Contributing

Improvements and suggestions welcome! Please open an issue or PR.

## License

MIT License - Use freely in any project.

## Credits

Based on session logging patterns from the Claude Code community and best practices in experimental development workflows.
