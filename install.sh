#!/bin/bash
# install.sh - Add session memory to an existing project
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/superelastic/claude-session-memory-template/main/install.sh | bash
#
# Or download and run:
#   ./install.sh [target-directory]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Determine target directory
TARGET_DIR="${1:-.}"
cd "$TARGET_DIR" || error "Cannot access directory: $TARGET_DIR"
TARGET_DIR=$(pwd)

echo "Installing session memory to: $TARGET_DIR"
echo ""

# Check if this looks like a project directory
if [ ! -d ".git" ]; then
    warn "Not a git repository. Session memory works best with git."
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]] || exit 1
fi

# Create temp directory for template
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Clone template
echo "Downloading template..."
git clone --depth 1 --quiet https://github.com/superelastic/claude-session-memory-template.git "$TEMP_DIR"

# Track what we're installing
INSTALLED=()
SKIPPED=()

# Install .claude directory
if [ -d ".claude" ]; then
    warn ".claude directory exists - merging (won't overwrite existing files)"
    # Copy hooks if not present
    mkdir -p .claude/hooks
    for file in "$TEMP_DIR/.claude/hooks/"*; do
        basename=$(basename "$file")
        if [ ! -f ".claude/hooks/$basename" ]; then
            cp "$file" ".claude/hooks/"
            INSTALLED+=(".claude/hooks/$basename")
        else
            SKIPPED+=(".claude/hooks/$basename (exists)")
        fi
    done
    # Copy protocol files if not present
    for file in "$TEMP_DIR/.claude/"*.md; do
        basename=$(basename "$file")
        if [ ! -f ".claude/$basename" ]; then
            cp "$file" ".claude/"
            INSTALLED+=(".claude/$basename")
        else
            SKIPPED+=(".claude/$basename (exists)")
        fi
    done
else
    cp -r "$TEMP_DIR/.claude" .
    # Remove settings files (user should configure these)
    rm -f .claude/settings.json.example .claude/settings.local.json 2>/dev/null || true
    INSTALLED+=(".claude/ (directory)")
fi

# Install scripts
mkdir -p scripts
for script in archive-session.sh convert_session.py; do
    if [ ! -f "scripts/$script" ]; then
        cp "$TEMP_DIR/scripts/$script" scripts/
        chmod +x "scripts/$script" 2>/dev/null || true
        INSTALLED+=("scripts/$script")
    else
        SKIPPED+=("scripts/$script (exists)")
    fi
done

# Install scratchpad
if [ ! -f "scratchpad.md" ]; then
    cat > scratchpad.md << 'EOF'
# Project Scratchpad

Last updated: $(date +%Y-%m-%d)

## Currently Working On

(Nothing yet)

## Open Items

- [ ] (Add tasks here)

## Notes

(Add notes here)
EOF
    INSTALLED+=("scratchpad.md")
else
    SKIPPED+=("scratchpad.md (exists)")
fi

# Create directories
mkdir -p .session_logs
mkdir -p docs/investigations
INSTALLED+=(".session_logs/ (directory)")
INSTALLED+=("docs/investigations/ (directory)")

# Create investigations index if not present
if [ ! -f "docs/investigations/INDEX.md" ]; then
    cat > docs/investigations/INDEX.md << 'EOF'
# Investigations Index

## In Progress

(None currently)

## Completed

(None yet)
EOF
    INSTALLED+=("docs/investigations/INDEX.md")
else
    SKIPPED+=("docs/investigations/INDEX.md (exists)")
fi

# Update .gitignore
GITIGNORE_ADDITIONS=""
if [ -f ".gitignore" ]; then
    # Check what's missing
    if ! grep -q "\.session_logs/\*\*/\*\.jsonl" .gitignore 2>/dev/null; then
        GITIGNORE_ADDITIONS+=".session_logs/**/*.jsonl"$'\n'
    fi
    if ! grep -q "\.claude/settings\.local\.json" .gitignore 2>/dev/null; then
        GITIGNORE_ADDITIONS+=".claude/settings.local.json"$'\n'
    fi
else
    GITIGNORE_ADDITIONS=".session_logs/**/*.jsonl"$'\n'".claude/settings.local.json"$'\n'
fi

if [ -n "$GITIGNORE_ADDITIONS" ]; then
    echo "" >> .gitignore
    echo "# Session memory" >> .gitignore
    echo "$GITIGNORE_ADDITIONS" >> .gitignore
    INSTALLED+=(".gitignore (updated)")
fi

# Summary
echo ""
echo "=== Installation Complete ==="
echo ""

if [ ${#INSTALLED[@]} -gt 0 ]; then
    echo -e "${GREEN}Installed:${NC}"
    for item in "${INSTALLED[@]}"; do
        echo "  ✓ $item"
    done
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Skipped:${NC}"
    for item in "${SKIPPED[@]}"; do
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
echo "   - At session end: \`./scripts/archive-session.sh\`"
echo "   - Search past work: \`rg -l \"term\" docs/investigations/\`"
echo ""
echo "2. Commit the changes:"
echo "   git add .claude scripts scratchpad.md docs/investigations .gitignore"
echo "   git commit -m 'Add session memory system'"
echo ""
echo "3. Start a new Claude Code session to activate hooks"
echo ""
