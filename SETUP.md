# Setup Guide

## Prerequisites

### System Requirements

- **Linux/Mac:** Works natively
- **Windows:** Requires WSL (Windows Subsystem for Linux)

### Software Requirements

- Claude Code installed
- Python 3.8+
- Git

## Installation

### 1. Create New Project from Template

**Option A: GitHub (Recommended)**
1. Click "Use this template" on GitHub
2. Name your new repository
3. Clone your new repository

**Option B: Manual Copy**
```bash
git clone https://github.com/user/claude-session-memory-template.git my-project
cd my-project
rm -rf .git
git init
git add .
git commit -m "Initial commit from template"
```

### 2. Install Python Dependencies

```bash
pip install -r scripts/requirements.txt
```

This installs:
- `sentence-transformers` - For semantic search
- `torch` - Required by sentence-transformers

**Note:** First run will download the embedding model (~400MB). This happens once.

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 4. Verify Setup

```bash
# Test archive script (will fail with no sessions yet - expected)
./scripts/archive-session.sh

# Test semantic filter (will work but find nothing)
python scripts/semantic_filter.py "test query"

# Check directory structure
tree -L 2 -a
```

## Configuration

### Git Configuration

The template includes `.gitignore` with sensible defaults:
- Ignores Python cache files
- Ignores model cache
- Tracks session logs (intentional - they're your project memory)

**Review `.gitignore`:**
```bash
cat .gitignore
```

### Editor Integration (Optional)

**VS Code:**
Add to `.vscode/tasks.json`:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Archive Claude Session",
      "type": "shell",
      "command": "./scripts/archive-session.sh",
      "problemMatcher": []
    }
  ]
}
```

**Shell Alias:**
```bash
# Add to ~/.bashrc or ~/.zshrc
alias archive-session='./scripts/archive-session.sh'
```

## First Session

### 1. Start Claude Code

```bash
claude-code .
```

### 2. Tell Claude About Protocols

```
You: "Read .claude/STARTUP_PROTOCOL.md and follow the startup procedure"
```

Claude will:
- Check for previous sessions (none yet)
- Read `scratchpad.md`
- Offer to start new work

### 3. Work on Something

Example:
```
You: "Let's test connecting to an API and see what rate limits exist"

Claude: [investigates with you]
```

### 4. Archive the Session

```bash
./scripts/archive-session.sh
```

**Output:**
```
✓ Copied JSONL: .session_logs/2025-12/28_1430_raw.jsonl
✓ Converted to markdown: .session_logs/2025-12/28_1430_raw.md

Session archived. Size: 156K
Ready to commit with: git commit -m 'Session: [description]'
```

### 5. Commit

```bash
git add .session_logs/
git commit -m "Session: Initial API exploration"
```

## Typical Usage Pattern

### Daily Workflow

**Morning:**
```bash
cd ~/projects/my-project
claude-code .
```

```
You: "Start session, check startup protocol"

Claude: [reads last session, checks scratchpad]
Claude: "Yesterday we were investigating rate limits. Found actual limit is 60/min. 
         From scratchpad: TODO - implement rate limiter class. Continue?"
```

**During Work:**
- Claude automatically captures everything
- Work progresses naturally

**End of Session:**
```bash
./scripts/archive-session.sh
git add .session_logs/
git commit -m "Session: Implemented rate limiter class"
```

**After Completing Investigation:**
```
You: "Create investigation doc for rate limiting following the template"

Claude: [creates docs/investigations/rate_limit_analysis.md]
```

```bash
git add docs/investigations/
git commit -m "Investigation: Rate limit analysis - actual limit is 60/min"
```

### Weekly Pattern

**End of Week:**
```bash
# Review this week's investigations
ls -lh docs/investigations/

# Update scratchpad - archive completed items
vim scratchpad.md

# Review session logs
ls -lh .session_logs/2025-12/
```

## Searching Past Work

### Simple Grep (Fast)

```bash
# Find investigations mentioning "authentication"
rg -l "authentication" docs/investigations/

# Find with context
rg "authentication" docs/investigations/
```

### Semantic Search (Comprehensive)

When grep returns too many results (>20), use semantic search:

```bash
python scripts/semantic_filter.py "API authentication strategies and implementation patterns"
```

**Output:**
```
Loading embedding model (first run only)...
Embedding 15 documents...
  0.876 - docs/investigations/oauth_implementation.md
  0.831 - docs/investigations/jwt_strategy.md
  0.782 - docs/investigations/api_key_management.md
  0.654 - docs/investigations/token_refresh.md
  0.621 - docs/investigations/session_handling.md
```

## Troubleshooting

### "No session found in ~/.claude/projects/..."

**Cause:** Working in native Windows instead of WSL, or wrong directory.

**Solution:**
```bash
# Check where Claude stores sessions for this project
PROJECT_DIR=$(pwd)
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's/\//-/g')
echo "Looking for: ~/.claude/projects/$ENCODED_PATH"
ls ~/.claude/projects/$ENCODED_PATH
```

If directory doesn't exist:
1. Verify you're in WSL (not Windows)
2. Verify Claude Code has been run in this project
3. Check `~/.claude/projects/` for the correct encoded path

### "archive-session.sh: command not found"

**Solution:**
```bash
# Make executable
chmod +x scripts/archive-session.sh

# Run with explicit path
./scripts/archive-session.sh
```

### "ModuleNotFoundError: No module named 'sentence_transformers'"

**Solution:**
```bash
pip install -r scripts/requirements.txt
```

### Sessions archived but can't find them

**Check:**
```bash
# List archived sessions
ls -lh .session_logs/*/*.jsonl

# View most recent
ls -t .session_logs/*/*.jsonl | head -1 | xargs cat | head -20
```

## Advanced Configuration

### Custom Embedding Model

Edit `scripts/semantic_filter.py`:

```python
# Default (best quality/speed balance):
MODEL = SentenceTransformer('BAAI/bge-large-en-v1.5')

# Faster, smaller (if speed critical):
MODEL = SentenceTransformer('all-MiniLM-L6-v2')

# Best quality (slower, larger):
MODEL = SentenceTransformer('all-mpnet-base-v2')
```

### Adjust Session Archive Format

Edit `scripts/convert_session.py` to customize markdown output format.

### Add Custom Protocols

Create additional protocol files in `.claude/`:
- `DEBUGGING_PROTOCOL.md`
- `CODE_REVIEW_PROTOCOL.md`
- `TESTING_PROTOCOL.md`

Reference them in sessions:
```
You: "Follow .claude/DEBUGGING_PROTOCOL.md for this investigation"
```

## Next Steps

1. **Read [WORKFLOWS.md](WORKFLOWS.md)** - Common workflow patterns
2. **Read [ARCHITECTURE.md](ARCHITECTURE.md)** - Understand how it works
3. **Start using it** - Best way to learn is by doing
4. **Customize** - Adapt protocols and scripts to your needs

## Getting Help

- **Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md)** for common issues
- **Inspect protocol docs** in `.claude/` for detailed procedures
- **Review example investigations** (once you've created some)
- **Open an issue** on GitHub if you find bugs or have suggestions
