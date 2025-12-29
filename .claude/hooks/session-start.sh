#!/bin/bash
# Session Start Hook - Injects project context into Claude's awareness
# Output from this script (with exit 0) is added to Claude's context

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(dirname "$0")/../.."

echo "=== SESSION CONTEXT ==="
echo ""

# Show scratchpad (current work and TODOs)
if [ -f "scratchpad.md" ]; then
    echo "## Scratchpad"
    echo ""
    cat scratchpad.md | head -50
    echo ""
fi

# Show recent session logs (last 3)
echo "## Recent Sessions"
echo ""
RECENT_SESSIONS=$(ls -t .session_logs/*/*.md 2>/dev/null | head -3)
if [ -n "$RECENT_SESSIONS" ]; then
    for session in $RECENT_SESSIONS; do
        echo "- $session"
    done
    echo ""
    # Show summary from most recent session (first 20 lines)
    LATEST=$(echo "$RECENT_SESSIONS" | head -1)
    if [ -f "$LATEST" ]; then
        echo "### Latest Session Summary"
        echo ""
        head -40 "$LATEST"
        echo ""
        echo "[... truncated, read full file if needed ...]"
    fi
else
    echo "(No archived sessions yet)"
fi
echo ""

# Show active investigations
echo "## Active Investigations"
echo ""
if [ -f "docs/investigations/INDEX.md" ]; then
    grep -A 5 "### Planned\|### In Progress" docs/investigations/INDEX.md 2>/dev/null | head -15
else
    echo "(No investigations index)"
fi

echo ""
echo "=== END SESSION CONTEXT ==="

exit 0
