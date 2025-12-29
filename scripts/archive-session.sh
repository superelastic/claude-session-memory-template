#!/bin/bash
# archive-session.sh - Archive Claude Code session to project

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
  echo ""
  echo "This could mean:"
  echo "1. Claude Code hasn't been run in this project yet"
  echo "2. You're not in a project root directory"
  echo "3. On Windows, you need to run this from WSL"
  exit 1
fi

# Find sessions with meaningful content (user/assistant messages)
# Sort by size descending - larger files have more content
SESSIONS_BY_SIZE=$(ls -S "$CLAUDE_SESSION_DIR"/*.jsonl 2>/dev/null | grep -v "agent-")

if [ -z "$SESSIONS_BY_SIZE" ]; then
  echo "❌ No session files found in $CLAUDE_SESSION_DIR"
  ls -la "$CLAUDE_SESSION_DIR"
  exit 1
fi

# Find first session with actual user/assistant content
LATEST_SESSION=""
for session in $SESSIONS_BY_SIZE; do
  # Check if session has user or assistant messages (semantic check)
  if grep -q '"type":"user"\|"type":"assistant"' "$session" 2>/dev/null; then
    LATEST_SESSION="$session"
    break
  fi
done

if [ -z "$LATEST_SESSION" ]; then
  echo "❌ No sessions with meaningful content found"
  echo "Sessions checked:"
  for s in $SESSIONS_BY_SIZE; do
    echo "  - $(basename "$s") ($(du -h "$s" | cut -f1))"
  done
  exit 1
fi

# Create target directory
TARGET_DIR=".session_logs/$(date +%Y-%m)"
mkdir -p "$TARGET_DIR"

# Target files
BASENAME="$(date +%d_%H%M)_raw"
TARGET_JSONL="$TARGET_DIR/${BASENAME}.jsonl"
TARGET_MD="$TARGET_DIR/${BASENAME}.md"

# Copy JSONL
cp "$LATEST_SESSION" "$TARGET_JSONL"
echo "✓ Copied JSONL: $TARGET_JSONL"

# Convert to markdown if converter exists
if [ -f "scripts/convert_session.py" ]; then
  if python3 scripts/convert_session.py "$TARGET_JSONL" "$TARGET_MD" 2>/dev/null; then
    echo "✓ Converted to markdown: $TARGET_MD"
  else
    echo "⚠ Conversion to markdown failed (not critical)"
  fi
fi

# Add to git staging
git add "$TARGET_JSONL" "$TARGET_MD" 2>/dev/null || true

echo ""
echo "Session archived. Size: $(du -h "$LATEST_SESSION" | cut -f1)"
echo "Source: $LATEST_SESSION"
echo ""
echo "Next steps:"
echo "  git commit -m 'Session: [description]'"
