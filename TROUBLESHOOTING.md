# Troubleshooting Guide

Common issues and solutions when using the claude-session-memory-template.

## Installation Issues

### "ModuleNotFoundError: No module named 'sentence_transformers'"

**Solution:**
```bash
pip install -r scripts/requirements.txt
```

If that fails:
```bash
pip install sentence-transformers torch --upgrade
```

### "torch not found" or PyTorch installation fails

**For CPU-only (simpler):**
```bash
pip install torch --index-url https://download.pytorch.org/whl/cpu
pip install sentence-transformers
```

**For GPU (if you have CUDA):**
```bash
# Check CUDA version first
nvidia-smi

# Install matching PyTorch version
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
pip install sentence-transformers
```

## Session Archiving Issues

### "No Claude sessions found for this project"

**Causes:**
1. Claude Code hasn't been run in this project yet
2. Not in project root directory
3. On Windows, not running from WSL

**Solutions:**

**Check if sessions exist:**
```bash
PROJECT_DIR=$(pwd)
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's/\//-/g')
ls ~/.claude/projects/$ENCODED_PATH
```

**If directory doesn't exist:**
- Run Claude Code at least once: `claude-code .`
- Verify you're in the correct directory
- On Windows, ensure you're in WSL, not native Windows

### "archive-session.sh: Permission denied"

**Solution:**
```bash
chmod +x scripts/archive-session.sh
chmod +x scripts/convert_session.py
chmod +x scripts/semantic_filter.py
```

### Sessions archived but can't find them

**Check:**
```bash
# List all archived sessions
ls -lh .session_logs/*/*.jsonl

# View most recent
ls -t .session_logs/*/*.md | head -1 | xargs cat | head -50
```

## Windows/WSL Issues

### "This requires WSL" - I'm on Windows

**Install WSL:**
```powershell
# In PowerShell (Admin)
wsl --install

# Restart computer
# After restart, open Ubuntu from Start menu
```

**Move project to WSL:**
```bash
# In WSL terminal
cd ~
mkdir -p projects
cd projects
git clone https://github.com/youruser/yourproject.git
cd yourproject

# Install dependencies
pip install -r scripts/requirements.txt

# Now Claude Code will work properly
claude-code .
```

### Sessions not found on Windows

**Problem:** Claude Code on Windows stores sessions differently than WSL.

**Solution:** Always use Claude Code from WSL, not native Windows.

```bash
# Bad (Windows):
C:\> cd C:\Users\youruser\projects\myproject
C:\> claude-code .

# Good (WSL):
$ cd /home/youruser/projects/myproject
$ claude-code .
```

## Semantic Search Issues

### Semantic search is very slow (>30 seconds)

**Cause:** Running on CPU without optimization.

**Solutions:**

**1. Use faster model (trade quality for speed):**

Edit `scripts/semantic_filter.py`:
```python
# Change this line:
MODEL = SentenceTransformer('BAAI/bge-large-en-v1.5')

# To this (3-5x faster):
MODEL = SentenceTransformer('all-MiniLM-L6-v2')
```

**2. Use GPU (if available):**
```bash
# Install CUDA-enabled PyTorch
pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
```

**3. Limit number of files searched:**
```bash
# Instead of searching everything:
python scripts/semantic_filter.py "query" docs/investigations/*.md

# Limit to recent:
find docs/investigations/ -name "*.md" -mtime -30 | \
  xargs python scripts/semantic_filter.py "query"
```

### "RuntimeError: CUDA out of memory"

**Solution:** Fall back to CPU:
```python
# In scripts/semantic_filter.py, add at top:
import os
os.environ['CUDA_VISIBLE_DEVICES'] = ''  # Force CPU
```

### Semantic search returns irrelevant results

**Diagnostics:**

1. **Check similarity scores** - should be >0.6 for relevant docs
2. **Refine query** - be more specific
3. **Check doc quality** - are investigation docs well-written?

**Better queries:**
```bash
# Too generic:
python scripts/semantic_filter.py "API"

# Better:
python scripts/semantic_filter.py "API rate limiting implementation with exponential backoff"

# Best:
python scripts/semantic_filter.py "How did we implement API rate limiting for the ThetaData API?"
```

## Claude Code Issues

### Claude doesn't follow protocols at session start

**Solution:** Explicitly prompt:
```
User: "Read .claude/STARTUP_PROTOCOL.md and follow the startup procedure"
```

**Make it automatic:** Add to project README or first comment in main file.

### Claude doesn't create investigation docs properly

**Check:**
1. Is template present? `ls docs/investigations/INVESTIGATION_TEMPLATE.md`
2. Prompt explicitly: `"Create investigation doc following the template"`
3. Review and edit the generated doc if needed

### Investigation doc missing frontmatter

**Fix manually:**
```markdown
---
type: investigation
source_sessions:
  - .session_logs/2025-12/28_1430_raw.jsonl
date: 2025-12-28
status: concluded
tags: [api, rate-limiting, performance]
---

# Rest of investigation...
```

## Git Issues

### Accidentally committed large model files

**Solution:**
```bash
# Add to .gitignore if not already there
echo ".cache/" >> .gitignore
echo "models/" >> .gitignore

# Remove from git (but keep locally)
git rm --cached -r .cache/ models/

git commit -m "Remove model cache from git"
```

### Session logs making repository too large

**Check sizes:**
```bash
du -sh .session_logs/
```

**If truly too large (>100MB is fine, >1GB is getting large):**

1. **Archive old sessions:**
```bash
# Move sessions older than 90 days to archive
find .session_logs/ -name "*.jsonl" -mtime +90 -exec mkdir -p archive \; -exec mv {} archive/ \;
```

2. **Use git-lfs for large files (optional):**
```bash
git lfs install
git lfs track ".session_logs/**/*.jsonl"
```

## Search Issues

### Can't find past work that definitely exists

**Diagnostics:**

1. **Check filename:**
```bash
ls docs/investigations/
```

2. **Try different search terms:**
```bash
rg -i "alternative_term" docs/investigations/
```

3. **Check if it's in a session log instead:**
```bash
rg "search_term" .session_logs/
```

4. **Use semantic search:**
```bash
python scripts/semantic_filter.py "what you're looking for"
```

### Grep returns too many results

**Solutions:**

1. **Use semantic filter:**
```bash
python scripts/semantic_filter.py "specific query"
```

2. **Filter by tags:**
```bash
rg -l "tags:.*api" docs/investigations/ | xargs rg -l "authentication"
```

3. **Filter by date:**
```bash
find docs/investigations/ -name "*.md" -mtime -30 | xargs rg -l "search_term"
```

4. **Filter by status:**
```bash
rg -l "status: concluded" docs/investigations/ | xargs rg -l "search_term"
```

## Performance Issues

### First semantic search takes forever

**This is normal** - downloading model (~400MB) on first run.

**To pre-download:**
```bash
python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('BAAI/bge-large-en-v1.5')"
```

### Subsequent searches still slow

**Add caching** (advanced):

Edit `scripts/semantic_filter.py` to cache embeddings. See SEMANTIC_SEARCH_IMPLEMENTATION.md for details.

## Protocol Issues

### Scratchpad becoming cluttered

**Solution - weekly cleanup:**
```bash
# Archive completed items
cat >> scratchpad_archive.md << EOF
## Week of $(date +%Y-%m-%d)
$(grep "✓" scratchpad.md)
EOF

# Remove from scratchpad
sed -i '/✓/d' scratchpad.md
```

### Investigation INDEX.md out of sync

**Solution - rebuild:**
```bash
# List all investigations
ls -1 docs/investigations/*.md | grep -v "INDEX\|TEMPLATE"

# Manually add to INDEX.md in appropriate categories
```

## Getting Help

If issue persists:

1. **Check protocol docs** in `.claude/` - they're the source of truth
2. **Review example workflows** in WORKFLOWS.md
3. **Verify setup** with health check:
   ```bash
   ls -la .session_logs/ docs/investigations/ .claude/ scripts/
   ```
4. **Try minimal test case** to isolate problem
5. **Open an issue** on GitHub with:
   - What you tried
   - What you expected
   - What actually happened
   - System info (OS, Python version, etc.)

## Quick Diagnostic Commands

```bash
# Verify directory structure
tree -L 2 -a

# Check Python dependencies
pip list | grep -E "sentence|torch"

# Test archive script (dry run)
./scripts/archive-session.sh 2>&1 | head -20

# Test semantic filter
echo "test" > /tmp/test.md
python scripts/semantic_filter.py "test" /tmp/test.md

# Check Claude session location
ls ~/.claude/projects/
```
