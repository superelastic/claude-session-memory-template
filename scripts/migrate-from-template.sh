#!/usr/bin/env bash
# migrate-from-template.sh — Migrate a project from the old session-memory
# template to the plugin version. Safe to run multiple times (idempotent).
#
# Usage: bash migrate-from-template.sh [--dry-run] [project-dir]
#
# - Removes old template infrastructure files
# - Updates CLAUDE.md with plugin snippet
# - Preserves all data (sessions/, .session_logs/, docs/, scratchpad.md)

set -euo pipefail

DRY_RUN=false
PROJECT_DIR=""

for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY_RUN=true ;;
        *) PROJECT_DIR="$arg" ;;
    esac
done

PROJECT_DIR="${PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

if [ ! -d "$PROJECT_DIR/.git" ] && [ ! -f "$PROJECT_DIR/CLAUDE.md" ]; then
    echo "ERROR: $PROJECT_DIR doesn't look like a project root (no .git or CLAUDE.md)"
    exit 1
fi

cd "$PROJECT_DIR"

removed=0
skipped=0

remove_if_exists() {
    local file="$1"
    if [ -e "$file" ]; then
        if $DRY_RUN; then
            echo "  [dry-run] would remove: $file"
        else
            rm -f "$file"
            echo "  removed: $file"
        fi
        removed=$((removed + 1))
    else
        skipped=$((skipped + 1))
    fi
}

echo "=== Session Memory: Template → Plugin Migration ==="
echo "Project: $PROJECT_DIR"
$DRY_RUN && echo "Mode: DRY RUN (no changes will be made)"
echo ""

# --- Step 1: Remove old commands ---
echo "Step 1: Old slash commands"
remove_if_exists ".claude/commands/startup.md"
remove_if_exists ".claude/commands/session-end.md"
if ! $DRY_RUN; then
    rmdir .claude/commands 2>/dev/null && echo "  removed: .claude/commands/" || true
fi

# --- Step 2: Remove old hooks ---
echo "Step 2: Old hook scripts"
remove_if_exists ".claude/hooks/session-start.sh"
remove_if_exists ".claude/hooks/session-end.sh"
if ! $DRY_RUN; then
    rmdir .claude/hooks 2>/dev/null && echo "  removed: .claude/hooks/" || true
fi

# --- Step 3: Remove old protocols ---
echo "Step 3: Old protocol files"
remove_if_exists ".claude/STARTUP_PROTOCOL.md"
remove_if_exists ".claude/SESSION_END_PROTOCOL.md"
remove_if_exists ".claude/INVESTIGATION_PROTOCOL.md"
remove_if_exists ".claude/RETRIEVAL_PROTOCOL.md"

# --- Step 4: Remove old settings example ---
echo "Step 4: Old settings"
remove_if_exists ".claude/settings.json.example"
remove_if_exists ".claude/settings.local.json"

# --- Step 5: Remove old scripts (now in plugin) ---
echo "Step 5: Old scripts"
remove_if_exists "scripts/archive-session.sh"
remove_if_exists "scripts/convert_session.py"
remove_if_exists "scripts/semantic_filter.py"
remove_if_exists "scripts/requirements.txt"
# Clean up scripts/ dir if empty
if [ -d "scripts" ] && [ -z "$(ls -A scripts 2>/dev/null)" ]; then
    $DRY_RUN && echo "  [dry-run] would remove: scripts/" || { rmdir scripts && echo "  removed: scripts/"; }
fi

# --- Step 6: Remove old template docs ---
echo "Step 6: Old template docs"
remove_if_exists "SETUP.md"
remove_if_exists "ARCHITECTURE.md"
remove_if_exists "WORKFLOWS.md"
remove_if_exists "TROUBLESHOOTING.md"
remove_if_exists "TEMPLATE_SUMMARY.md"
remove_if_exists "install.sh"

# --- Step 7: Update CLAUDE.md ---
echo "Step 7: CLAUDE.md"

# The snippet to inject
SNIPPET='## Session Memory

This project uses the **session-memory** plugin for continuity between Claude Code sessions. All memory is git-versioned and travels with the repo.

### How It Works

- **Automatic**: Hooks archive sessions on end and restore context on start
- **Pending queue**: Sessions captured immediately, summarized intelligently at next start
- **Searchable**: Past work is searchable via MCP tools or keyword search

### Key Directories

- `sessions/` — AI-generated session summaries
- `docs/investigations/` — Hypothesis-driven research records
- `docs/decisions/` — Architecture Decision Records
- `docs/reference/` — Methodologies and quick references
- `.session_logs/` — Raw session archives
- `scratchpad.md` — Current work tracking and TODOs

### Commands

- `/session-memory:startup` — Manually load context from previous sessions
- `/session-memory:session-end` — Manually archive and summarize current session
- `/session-memory:search <query>` — Search past sessions and documentation'

if [ -f "CLAUDE.md" ]; then
    if grep -q "session-memory.* plugin" CLAUDE.md; then
        echo "  CLAUDE.md already has plugin snippet — skipped"
    elif grep -q "Session Memory" CLAUDE.md; then
        if $DRY_RUN; then
            echo "  [dry-run] would replace old Session Memory section in CLAUDE.md"
        else
            # Remove old section (from "## Session Memory" to next "## " or EOF)
            # Use python for reliable multiline replacement
            python3 -c "
import re, sys
with open('CLAUDE.md', 'r') as f:
    content = f.read()
# Match from '## Session Memory' to next '## ' heading or EOF
pattern = r'## Session Memory.*?(?=\n## [^#]|\Z)'
new_content = re.sub(pattern, '''$SNIPPET''', content, count=1, flags=re.DOTALL)
with open('CLAUDE.md', 'w') as f:
    f.write(new_content)
"
            echo "  replaced old Session Memory section with plugin version"
        fi
    else
        if $DRY_RUN; then
            echo "  [dry-run] would append Session Memory section to CLAUDE.md"
        else
            printf "\n\n%s\n" "$SNIPPET" >> CLAUDE.md
            echo "  appended Session Memory section to CLAUDE.md"
        fi
    fi
else
    if $DRY_RUN; then
        echo "  [dry-run] would create CLAUDE.md with Session Memory section"
    else
        echo "$SNIPPET" > CLAUDE.md
        echo "  created CLAUDE.md with Session Memory section"
    fi
fi

# --- Summary ---
echo ""
echo "=== Migration Complete ==="
echo "Removed: $removed file(s)"
echo "Already clean: $skipped file(s)"
echo ""
echo "Data preserved (untouched):"
[ -d "sessions" ]       && echo "  sessions/        — $(ls sessions/ 2>/dev/null | wc -l) file(s)"
[ -d ".session_logs" ]  && echo "  .session_logs/   — $(find .session_logs -name '*.md' -o -name '*.jsonl' 2>/dev/null | wc -l) file(s)"
[ -d "docs" ]           && echo "  docs/            — $(find docs -name '*.md' 2>/dev/null | wc -l) file(s)"
[ -f "scratchpad.md" ]  && echo "  scratchpad.md    — preserved"
echo ""
if $DRY_RUN; then
    echo "This was a dry run. Re-run without --dry-run to apply changes."
else
    echo "Next steps:"
    echo "  1. Review changes: git diff"
    echo "  2. Commit: git add -A && git commit -m 'Migrate to session-memory plugin'"
    echo "  3. Verify: /session-memory:startup"
fi
