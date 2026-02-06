#!/bin/bash
# install.sh - Add session memory to an existing project
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/superelastic/claude-session-memory-template/main/install.sh | bash
#
# Or download and run:
#   ./install.sh [target-directory]

set -e

info() { echo "[OK] $1"; }
warn() { echo "[WARN] $1"; }
error() { echo "[ERROR] $1"; exit 1; }

TARGET_DIR="${1:-.}"
cd "$TARGET_DIR" || error "Cannot access directory: $TARGET_DIR"
TARGET_DIR=$(pwd)

echo "Installing session memory to: $TARGET_DIR"
echo ""

if [ ! -d ".git" ]; then
    warn "Not a git repository. Session memory works best with git."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Downloading template..."
git clone --depth 1 --quiet https://github.com/superelastic/claude-session-memory-template.git "$TEMP_DIR"

INSTALLED=""
SKIPPED=""

# --- .claude directory ---
if [ -d ".claude" ]; then
    warn ".claude directory exists - merging"

    # Hooks
    mkdir -p .claude/hooks
    for file in "$TEMP_DIR"/.claude/hooks/*; do
        bname=$(basename "$file")
        if [ ! -f ".claude/hooks/$bname" ]; then
            cp "$file" ".claude/hooks/"
            INSTALLED="$INSTALLED .claude/hooks/$bname"
        else
            SKIPPED="$SKIPPED .claude/hooks/$bname"
        fi
    done

    # Commands (slash commands)
    mkdir -p .claude/commands
    for file in "$TEMP_DIR"/.claude/commands/*; do
        bname=$(basename "$file")
        if [ ! -f ".claude/commands/$bname" ]; then
            cp "$file" ".claude/commands/"
            INSTALLED="$INSTALLED .claude/commands/$bname"
        else
            SKIPPED="$SKIPPED .claude/commands/$bname"
        fi
    done

    # Protocol docs
    for file in "$TEMP_DIR"/.claude/*.md; do
        bname=$(basename "$file")
        if [ ! -f ".claude/$bname" ]; then
            cp "$file" ".claude/"
            INSTALLED="$INSTALLED .claude/$bname"
        else
            SKIPPED="$SKIPPED .claude/$bname"
        fi
    done
else
    cp -r "$TEMP_DIR/.claude" .
    rm -f .claude/settings.json.example 2>/dev/null || true
    INSTALLED="$INSTALLED .claude/"
fi

# --- Hooks configuration ---
if [ ! -f ".claude/settings.local.json" ]; then
    cp "$TEMP_DIR/.claude/settings.json.example" .claude/settings.local.json
    INSTALLED="$INSTALLED .claude/settings.local.json"
    info "Hooks enabled via .claude/settings.local.json"
else
    warn ".claude/settings.local.json exists - review hooks configuration manually"
    if [ ! -f ".claude/settings.json.example" ]; then
        cp "$TEMP_DIR/.claude/settings.json.example" .claude/settings.json.example
        INSTALLED="$INSTALLED .claude/settings.json.example"
    fi
    SKIPPED="$SKIPPED .claude/settings.local.json"
fi

# --- Scripts ---
mkdir -p scripts
for script in archive-session.sh convert_session.py semantic_filter.py requirements.txt; do
    if [ ! -f "scripts/$script" ]; then
        cp "$TEMP_DIR/scripts/$script" scripts/
        chmod +x "scripts/$script" 2>/dev/null || true
        INSTALLED="$INSTALLED scripts/$script"
    else
        SKIPPED="$SKIPPED scripts/$script"
    fi
done

# --- Scratchpad ---
if [ ! -f "scratchpad.md" ]; then
    cat > scratchpad.md << 'SCRATCHPAD'
# Project Scratchpad

Last updated: (date)

## Currently Working On

(Nothing yet)

## Open Items

- [ ] (Add tasks here)

## Notes

(Add notes here)
SCRATCHPAD
    INSTALLED="$INSTALLED scratchpad.md"
else
    SKIPPED="$SKIPPED scratchpad.md"
fi

# --- Directory structure ---
mkdir -p .session_logs/pending
mkdir -p sessions
mkdir -p docs/investigations
mkdir -p docs/decisions
mkdir -p docs/reference
INSTALLED="$INSTALLED .session_logs/ sessions/ docs/"

# --- Template files for docs ---
if [ ! -f "docs/investigations/INDEX.md" ]; then
    cp "$TEMP_DIR/docs/investigations/INDEX.md" docs/investigations/
    INSTALLED="$INSTALLED docs/investigations/INDEX.md"
else
    SKIPPED="$SKIPPED docs/investigations/INDEX.md"
fi

if [ ! -f "docs/investigations/INVESTIGATION_TEMPLATE.md" ]; then
    cp "$TEMP_DIR/docs/investigations/INVESTIGATION_TEMPLATE.md" docs/investigations/
    INSTALLED="$INSTALLED docs/investigations/INVESTIGATION_TEMPLATE.md"
else
    SKIPPED="$SKIPPED docs/investigations/INVESTIGATION_TEMPLATE.md"
fi

for readme in decisions/README.md reference/README.md; do
    if [ ! -f "docs/$readme" ]; then
        cp "$TEMP_DIR/docs/$readme" "docs/$readme"
        INSTALLED="$INSTALLED docs/$readme"
    else
        SKIPPED="$SKIPPED docs/$readme"
    fi
done

# CLAUDE.md snippet for merging
if [ ! -f "docs/claude-session-memory.md" ]; then
    if [ -f "$TEMP_DIR/docs/claude-session-memory.md" ]; then
        cp "$TEMP_DIR/docs/claude-session-memory.md" docs/
    else
        cat > docs/claude-session-memory.md << 'SNIPPET'
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
SNIPPET
    fi
    INSTALLED="$INSTALLED docs/claude-session-memory.md"
else
    SKIPPED="$SKIPPED docs/claude-session-memory.md"
fi

# --- .gitignore ---
NEEDS_JSONL=true
NEEDS_SETTINGS=true
if [ -f ".gitignore" ]; then
    grep -q '\.session_logs/.*\.jsonl' .gitignore 2>/dev/null && NEEDS_JSONL=false
    grep -q '\.claude/settings\.local\.json' .gitignore 2>/dev/null && NEEDS_SETTINGS=false
fi

if $NEEDS_JSONL || $NEEDS_SETTINGS; then
    echo "" >> .gitignore
    echo "# Session memory" >> .gitignore
    $NEEDS_JSONL && echo ".session_logs/**/*.jsonl" >> .gitignore
    $NEEDS_SETTINGS && echo ".claude/settings.local.json" >> .gitignore
    INSTALLED="$INSTALLED .gitignore"
fi

# --- Output ---
echo ""
echo "=== Installation Complete ==="
echo ""

if [ -n "$INSTALLED" ]; then
    echo "Installed:"
    for item in $INSTALLED; do
        echo "  + $item"
    done
fi

if [ -n "$SKIPPED" ]; then
    echo ""
    echo "Skipped (already exist):"
    for item in $SKIPPED; do
        echo "  - $item"
    done
fi

echo ""
echo "=== Next Steps ==="
echo ""
if [ -f "CLAUDE.md" ]; then
    echo "1. Add session memory info to your CLAUDE.md:"
    echo "   - A snippet is ready at: docs/claude-session-memory.md"
    echo "   - Option A: Append it manually:  cat docs/claude-session-memory.md >> CLAUDE.md"
    echo "   - Option B: Use /merge-claude docs/claude-session-memory.md (if available)"
else
    echo "1. Create a CLAUDE.md for your project (try /init in Claude Code)"
    echo "   - Then add session memory info from: docs/claude-session-memory.md"
fi
echo ""
echo "2. (Optional) Install semantic search dependencies:"
echo "   pip install -r scripts/requirements.txt"
echo ""
echo "3. Commit the changes:"
echo "   git add .claude scripts scratchpad.md sessions docs .gitignore"
echo "   git commit -m 'Add session memory system'"
echo ""
echo "4. Start a new Claude Code session — hooks are already enabled"
echo ""
