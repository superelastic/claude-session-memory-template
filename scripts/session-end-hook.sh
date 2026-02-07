#!/bin/bash
# Session End Hook (plugin) - Archives the session to pending queue
# Runs before exit; cannot block session termination

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Ensure storage directories exist in host project
mkdir -p .session_logs/pending sessions docs/investigations docs/decisions docs/reference

# Run archive script from plugin directory
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ARCHIVE="$PLUGIN_ROOT/scripts/archive-session.sh"

if [ -f "$ARCHIVE" ]; then
    bash "$ARCHIVE"
else
    echo "Warning: archive-session.sh not found at $ARCHIVE"
fi

exit 0
