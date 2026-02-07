#!/bin/bash
# archive-session.sh - Archive Claude Code sessions with pending queue for summarization
#
# This script:
# 1. Finds unarchived session JSONL logs
# 2. Checks manifest to avoid re-processing
# 3. Archives JSONL and creates pending markdown for agent summarization
#
# The pending queue pattern:
#   SessionEnd → archive → pending/*.md
#   SessionStart → agent summarizes pending → sessions/*.md

set -e

# Resolve script directory (where convert_session.py lives)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Get current project directory (where sessions/docs live)
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
cd "$PROJECT_DIR"

# Encode project path the way Claude Code does (slashes to hyphens)
ENCODED_PATH=$(echo "$PROJECT_DIR" | sed 's|/|-|g')

# Claude's session directory for this project
CLAUDE_SESSION_DIR="$HOME/.claude/projects/$ENCODED_PATH"

# Check if directory exists
if [ ! -d "$CLAUDE_SESSION_DIR" ]; then
  echo "No Claude sessions found for this project"
  echo "Expected: $CLAUDE_SESSION_DIR"
  exit 0
fi

# Target directories
ARCHIVE_DIR=".session_logs/$(date +%Y-%m)"
PENDING_DIR=".session_logs/pending"
mkdir -p "$ARCHIVE_DIR" "$PENDING_DIR"

# Manifest file to track archived session UUIDs
MANIFEST=".session_logs/.manifest"
touch "$MANIFEST"

# Counters
ARCHIVED_COUNT=0
SKIPPED_COUNT=0

# Process all non-agent session files
for session in "$CLAUDE_SESSION_DIR"/*.jsonl; do
  [ -f "$session" ] || continue

  # Skip agent sessions
  BASENAME=$(basename "$session")
  [[ "$BASENAME" == agent-* ]] && continue

  # Extract session UUID from filename
  SESSION_UUID="${BASENAME%.jsonl}"
  SESSION_ID_SHORT="${SESSION_UUID:0:8}"

  # Check if this session was previously archived
  PREVIOUSLY_ARCHIVED=false
  if grep -q "^$SESSION_UUID$" "$MANIFEST" 2>/dev/null; then
    PREVIOUSLY_ARCHIVED=true
    # Check if source is newer than any existing archive (resumed session)
    EXISTING_MD=$(find .session_logs -name "*_${SESSION_ID_SHORT}.md" -not -path ".session_logs/pending/*" 2>/dev/null | head -1)
    if [ -n "$EXISTING_MD" ] && [ "$session" -nt "$EXISTING_MD" ]; then
      # Resumed session with new content - remove old archives
      echo "Updating resumed session: $SESSION_ID_SHORT"
      find .session_logs -name "*_${SESSION_ID_SHORT}.md" -delete 2>/dev/null
      find .session_logs -name "*_${SESSION_ID_SHORT}.jsonl" -delete 2>/dev/null
      # Remove from manifest to re-archive
      grep -v "^$SESSION_UUID$" "$MANIFEST" > "$MANIFEST.tmp" && mv "$MANIFEST.tmp" "$MANIFEST"
      PREVIOUSLY_ARCHIVED=false
    fi
  fi

  # Skip if already archived and not updated
  if [ "$PREVIOUSLY_ARCHIVED" = true ]; then
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

  # Get session timestamp from first entry
  FIRST_TS=$(grep -m1 '"timestamp"' "$session" 2>/dev/null | \
    sed -n 's/.*"timestamp":"\([0-9-]*\)T\([0-9:]*\).*/\1_\2/p' | \
    tr -d ':-' | cut -c1-13)

  # Fallback to file modification time if no timestamp found
  if [ -z "$FIRST_TS" ]; then
    FIRST_TS=$(date -r "$session" +%Y%m%d_%H%M)
  fi

  # Target filenames
  ARCHIVE_NAME="${FIRST_TS}_${SESSION_ID_SHORT}"
  TARGET_JSONL="$ARCHIVE_DIR/${ARCHIVE_NAME}.jsonl"
  PENDING_MD="$PENDING_DIR/${ARCHIVE_NAME}.md"

  # Skip if target already exists (safety check)
  if [ -f "$TARGET_JSONL" ]; then
    echo "$SESSION_UUID" >> "$MANIFEST"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  # Copy JSONL to archive
  cp "$session" "$TARGET_JSONL"

  # Convert to pending markdown (for agent summarization on next session start)
  if [ -f "$SCRIPT_DIR/convert_session.py" ]; then
    if python3 "$SCRIPT_DIR/convert_session.py" "$TARGET_JSONL" "$PENDING_MD" 2>/dev/null; then
      echo "Archived: $ARCHIVE_NAME (pending summarization)"
    else
      echo "Archived: $TARGET_JSONL (markdown conversion failed)"
    fi
  else
    echo "Archived: $TARGET_JSONL"
  fi

  # Mark as archived
  echo "$SESSION_UUID" >> "$MANIFEST"
  ARCHIVED_COUNT=$((ARCHIVED_COUNT + 1))
done

echo ""
if [ $ARCHIVED_COUNT -eq 0 ]; then
  echo "No new sessions to archive ($SKIPPED_COUNT already archived or empty)"
else
  echo "Archived $ARCHIVED_COUNT session(s), skipped $SKIPPED_COUNT"
  echo "Pending files will be summarized on next session start"
fi
