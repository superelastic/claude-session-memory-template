#!/bin/bash
# Session Start Hook - Injects context and signals pending summaries
# Output from this script (with exit 0) is added to Claude's context

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(dirname "$0")/../.."

echo "=== SESSION CONTEXT ==="
echo ""

# Show scratchpad (current work and TODOs)
if [ -f "scratchpad.md" ]; then
    echo "## Scratchpad"
    echo ""
    head -50 scratchpad.md
    echo ""
fi

# Check for pending session summaries
PENDING_DIR=".session_logs/pending"
PENDING_COUNT=$(ls -1 "$PENDING_DIR"/*.md 2>/dev/null | wc -l)

if [ "$PENDING_COUNT" -gt 0 ]; then
    echo "## Pending Session Summaries"
    echo ""
    echo "There are $PENDING_COUNT session(s) awaiting summarization in $PENDING_DIR/"
    echo ""
    echo "The agent hook will process these and create summaries in sessions/"
    echo ""
    # List pending files
    for pending in "$PENDING_DIR"/*.md; do
        [ -f "$pending" ] && echo "  - $(basename "$pending")"
    done
    echo ""
fi

# Show most recent session summary (if exists)
echo "## Last Session"
echo ""
LAST_SESSION=$(ls -t sessions/*.md 2>/dev/null | head -1)
if [ -n "$LAST_SESSION" ] && [ -f "$LAST_SESSION" ]; then
    echo "### $(basename "$LAST_SESSION")"
    echo ""
    cat "$LAST_SESSION"
    echo ""
else
    echo "(No session summaries yet)"
fi

echo ""
echo "=== END SESSION CONTEXT ==="

exit 0
