#!/bin/bash
# Session End Hook - Archives the session automatically
# Note: This hook cannot block session termination, but runs before exit

cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || cd "$(dirname "$0")/../.."

# Archive the session
if [ -f "scripts/archive-session.sh" ]; then
    ./scripts/archive-session.sh
else
    echo "⚠ archive-session.sh not found, session not archived"
fi

# Reminder for manual steps (displayed but not blocking)
echo ""
echo "=== REMINDER ==="
echo "Manual steps if needed:"
echo "  1. Update scratchpad.md with open items"
echo "  2. git add . && git commit -m 'Session: [description]'"
echo ""

exit 0
