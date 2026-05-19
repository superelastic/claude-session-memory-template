#!/bin/bash
# Verifies that session-start-hook.sh emits the ACTION REQUIRED block
# and extracts a first-prompt preview from each pending file.
set -e

PLUGIN_ROOT=$(cd "$(dirname "$0")/.." && pwd)
HOOK="$PLUGIN_ROOT/scripts/session-start-hook.sh"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/.session_logs/pending"
cat > "$TMPDIR/.session_logs/pending/test.md" <<'EOF'
# Session: test

## User

First prompt that should appear in the preview line.
EOF

OUTPUT=$(CLAUDE_PROJECT_DIR="$TMPDIR" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
         bash "$HOOK")

echo "$OUTPUT" | grep -q "ACTION REQUIRED — Pending Session Summaries (1)" \
    || { echo "FAIL: ACTION REQUIRED header missing"; echo "$OUTPUT"; exit 1; }

echo "$OUTPUT" | grep -q "first prompt: First prompt that should appear" \
    || { echo "FAIL: preview not extracted"; echo "$OUTPUT"; exit 1; }

echo "PASS"
