#!/bin/bash
# Session Start Hook (plugin) - Injects context for the session-memory skill
# Output from this script (exit 0) is added to Claude's context

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Run archive first to catch any sessions missed by SessionEnd hook
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ARCHIVE="$PLUGIN_ROOT/scripts/archive-session.sh"
if [ -f "$ARCHIVE" ]; then
    bash "$ARCHIVE" 2>/dev/null
fi

echo "=== SESSION MEMORY CONTEXT ==="
echo ""

# Pending session summaries — PRINT FIRST so Claude sees the action item
# before scratchpad / last-session context.
PENDING_DIR=".session_logs/pending"
if [ -d "$PENDING_DIR" ]; then
    PENDING_COUNT=$(ls -1 "$PENDING_DIR"/*.md 2>/dev/null | wc -l)
    if [ "$PENDING_COUNT" -gt 0 ]; then
        echo "## ACTION REQUIRED — Pending Session Summaries ($PENDING_COUNT)"
        echo ""
        echo "Process these BEFORE responding to the user's first task. For each file:"
        echo "  1. Read .session_logs/pending/<file>"
        echo "  2. Write sessions/YYYY-MM-DD-<topic>.md (see skill for format)"
        echo "  3. Delete the pending file"
        echo ""
        echo "If the user's first message is short / casual, do the curation pass"
        echo "and then address it. If the message is a substantial task, ask the"
        echo "user once whether to curate first or defer — do not silently skip."
        echo ""
        for f in "$PENDING_DIR"/*.md; do
            [ -f "$f" ] || continue
            preview=$(awk '/^## User$/{flag=1;next} flag && NF{print;exit}' "$f" \
                      | tr -s '[:space:]' ' ' | cut -c1-100)
            echo "  - $(basename "$f")"
            [ -n "$preview" ] && echo "      first prompt: ${preview}…"
        done
        echo ""
    fi
fi

# Scratchpad
if [ -f "scratchpad.md" ]; then
    echo "## Scratchpad"
    echo ""
    head -50 scratchpad.md
    echo ""
fi

# Most recent session summary
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
