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

if [ -d ".claude" ]; then
    warn ".claude directory exists - merging"
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
    rm -f .claude/settings.json.example .claude/settings.local.json 2>/dev/null || true
    INSTALLED="$INSTALLED .claude/"
fi

mkdir -p scripts
for script in archive-session.sh convert_session.py; do
    if [ ! -f "scripts/$script" ]; then
        cp "$TEMP_DIR/scripts/$script" scripts/
        chmod +x "scripts/$script" 2>/dev/null || true
        INSTALLED="$INSTALLED scripts/$script"
    else
        SKIPPED="$SKIPPED scripts/$script"
    fi
done

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

mkdir -p .session_logs
mkdir -p docs/investigations
INSTALLED="$INSTALLED .session_logs/ docs/investigations/"

if [ ! -f "docs/investigations/INDEX.md" ]; then
    cat > docs/investigations/INDEX.md << 'INDEXMD'
# Investigations Index

## In Progress

(None currently)

## Completed

(None yet)
INDEXMD
    INSTALLED="$INSTALLED docs/investigations/INDEX.md"
else
    SKIPPED="$SKIPPED docs/investigations/INDEX.md"
fi

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
echo "1. Add to your CLAUDE.md:"
echo ""
echo "   ## Session Memory"
echo "   - At session start: Context auto-injected via hooks"
echo "   - At session end: ./scripts/archive-session.sh"
echo ""
echo "2. Commit the changes:"
echo "   git add .claude scripts scratchpad.md docs/investigations .gitignore"
echo "   git commit -m 'Add session memory system'"
echo ""
echo "3. Start a new Claude Code session to activate hooks"
echo ""
