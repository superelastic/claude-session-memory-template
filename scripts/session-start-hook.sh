#!/bin/bash
# Session Start Hook (plugin) - Injects context for the session-memory skill
# Output from this script (exit 0) is added to Claude's context

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

echo "=== SESSION MEMORY CONTEXT ==="
echo ""

# Show scratchpad
if [ -f "scratchpad.md" ]; then
    echo "## Scratchpad"
    echo ""
    head -50 scratchpad.md
    echo ""
fi

# List pending session files
PENDING_DIR=".session_logs/pending"
if [ -d "$PENDING_DIR" ]; then
    PENDING_COUNT=$(ls -1 "$PENDING_DIR"/*.md 2>/dev/null | wc -l)
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo "## Pending Session Summaries"
        echo ""
        echo "$PENDING_COUNT session(s) awaiting summarization in $PENDING_DIR/."
        echo "Process each: read the file, write a summary to sessions/, delete the pending file."
        echo ""
        for f in "$PENDING_DIR"/*.md; do
            [ -f "$f" ] && echo "  - $(basename "$f")"
        done
        echo ""
    fi
fi

# Show most recent session summary
if [ -d "sessions" ]; then
    LAST=$(ls -t sessions/*.md 2>/dev/null | head -1)
    if [ -n "$LAST" ] && [ -f "$LAST" ]; then
        echo "## Last Session"
        echo ""
        echo "### $(basename "$LAST")"
        echo ""
        cat "$LAST"
        echo ""
    fi
fi

echo "=== END SESSION MEMORY CONTEXT ==="
exit 0
