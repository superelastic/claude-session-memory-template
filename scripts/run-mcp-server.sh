#!/bin/bash
# Wrapper script to run the session-memory MCP server.
# Handles venv creation and dependency installation on first run.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VENV_DIR="$PLUGIN_DIR/.venv"

# Create venv if it doesn't exist
if [ ! -f "$VENV_DIR/bin/python3" ]; then
    python3 -m venv "$VENV_DIR" 2>/dev/null
    if [ $? -ne 0 ]; then
        echo "Error: Could not create Python venv. Ensure python3-venv is installed." >&2
        exit 1
    fi
    "$VENV_DIR/bin/pip" install --quiet mcp 2>/dev/null
fi

# Ensure mcp is installed
if ! "$VENV_DIR/bin/python3" -c "import mcp" 2>/dev/null; then
    "$VENV_DIR/bin/pip" install --quiet mcp 2>/dev/null
fi

exec "$VENV_DIR/bin/python3" "$SCRIPT_DIR/mcp_server.py" "$@"
