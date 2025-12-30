#!/bin/bash
# archive-session.sh - Archive ALL unarchived Claude Code sessions to project
#
# Archives every session with meaningful content that hasn't been archived yet.
# Tracks archived sessions by UUID to avoid duplicates.

set -e

# Get current project directory and encode it
PROJECT_DIR=$(pwd)
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's/\//-/g')

# Claude's session directory for this project
CLAUDE_SESSION_DIR="$HOME/.claude/projects/$ENCODED_PATH"

# Check if directory exists
if [ ! -d "$CLAUDE_SESSION_DIR" ]; then
  echo "❌ No Claude sessions found for this project"
  echo "Expected: $CLAUDE_SESSION_DIR"
  exit 1
fi

# Target directory for archived sessions
TARGET_DIR=".session_logs/$(date +%Y-%m)"
mkdir -p "$TARGET_DIR"

# Manifest file to track archived session UUIDs
MANIFEST=".session_logs/.archived_sessions"
touch "$MANIFEST"

# Counter for archived sessions
ARCHIVED_COUNT=0
SKIPPED_COUNT=0

# Process all non-agent session files
for session in "$CLAUDE_SESSION_DIR"/*.jsonl; do
  [ -f "$session" ] || continue

  # Skip agent sessions
  basename "$session" | grep -q "^agent-" && continue

  # Extract session UUID from filename
  SESSION_UUID=$(basename "$session" .jsonl)

  # Skip if already archived
  if grep -q "^$SESSION_UUID$" "$MANIFEST" 2>/dev/null; then
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Check if session has meaningful content (user/assistant messages)
  if ! grep -q '"type":"user"\|"type":"assistant"' "$session" 2>/dev/null; then
    # No meaningful content, mark as processed anyway
    echo "$SESSION_UUID" >> "$MANIFEST"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Get session timestamp from first entry, or use file modification time
  FIRST_TS=$(grep -m1 '"timestamp"' "$session" 2>/dev/null | sed -n 's/.*"timestamp":"\([0-9-]*\)T\([0-9:]*\).*/\1_\2/p' | tr -d ':-' | cut -c1-13)

  # Fallback to file modification time if no timestamp found
  if [ -z "$FIRST_TS" ]; then
    FIRST_TS=$(date -r "$session" +%Y%m%d_%H%M)
  fi

  # Target filenames using session UUID for uniqueness
  TARGET_JSONL="$TARGET_DIR/${FIRST_TS}_${SESSION_UUID:0:8}.jsonl"
  TARGET_MD="$TARGET_DIR/${FIRST_TS}_${SESSION_UUID:0:8}.md"

  # Skip if target already exists (safety check)
  if [ -f "$TARGET_JSONL" ]; then
    echo "$SESSION_UUID" >> "$MANIFEST"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Copy JSONL
  cp "$session" "$TARGET_JSONL"

  # Convert to markdown
  if [ -f "scripts/convert_session.py" ]; then
    if python3 scripts/convert_session.py "$TARGET_JSONL" "$TARGET_MD" 2>/dev/null; then
      echo "✓ Archived: $TARGET_MD ($(du -h "$TARGET_JSONL" | cut -f1))"
    else
      echo "✓ Archived: $TARGET_JSONL (markdown conversion failed)"
    fi
  else
    echo "✓ Archived: $TARGET_JSONL"
  fi

  # Mark as archived
  echo "$SESSION_UUID" >> "$MANIFEST"
  ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))

  # Stage markdown for git (JSONL is gitignored)
  git add "$TARGET_MD" 2>/dev/null || true
done

echo ""
if [ $ARCHIVED_COUNT -eq 0 ]; then
  echo "No new sessions to archive ($SKIPPED_COUNT already archived or empty)"
else
  echo "Archived $ARCHIVED_COUNT new session(s), skipped $SKIPPED_COUNT"
  echo ""
  echo "Next steps:"
  echo "  git commit -m 'Session: [description]'"
fi
