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

# Show recent session logs - inject FULL content of last 3 sessions
# Sessions are now compact (typically <10KB each) so this is feasible
echo "## Recent Sessions"
echo ""
# Sort by filename (new format: YYYYMMDD_HHMM_UUID.md) in reverse order
# Exclude old format files (*_raw.md) which may be duplicates
RECENT_SESSIONS=$(ls .session_logs/*/*.md 2>/dev/null | grep -v "_raw\.md$" | sort -r | head -3)
if [ -n "$RECENT_SESSIONS" ]; then
    for session in $RECENT_SESSIONS; do
        echo "### Session: $(basename "$session")"
        echo ""
        cat "$session"
        echo ""
        echo "---"
        echo ""
    done
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
