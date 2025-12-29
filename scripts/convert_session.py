#!/usr/bin/env python3
"""
convert_session.py - Convert Claude Code JSONL session to readable markdown

Handles the actual Claude Code session format:
- type: "user" with message.content (string)
- type: "assistant" with message.content (array of content blocks)
- type: "tool_use" with tool name and input
- type: "tool_result" with output

Usage:
    python convert_session.py input.jsonl output.md
"""

import json
import sys
from pathlib import Path
from datetime import datetime


def parse_timestamp(ts_str):
    """Parse ISO timestamp to readable format."""
    try:
        dt = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except:
        return ts_str


def extract_text_content(content):
    """Extract text from various content formats."""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        # Array of content blocks (assistant format)
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get('type') == 'text':
                    texts.append(block.get('text', ''))
                elif block.get('type') == 'tool_use':
                    texts.append(f"[Tool: {block.get('name', 'unknown')}]")
            elif isinstance(block, str):
                texts.append(block)
        return '\n'.join(texts)
    elif isinstance(content, dict):
        return content.get('text', str(content))
    return str(content)


def has_meaningful_content(jsonl_path):
    """Check if session has actual user/assistant messages."""
    try:
        with open(jsonl_path, 'r', encoding='utf-8') as f:
            user_count = 0
            assistant_count = 0
            for line in f:
                try:
                    entry = json.loads(line)
                    entry_type = entry.get('type', '')
                    if entry_type == 'user':
                        user_count += 1
                    elif entry_type == 'assistant':
                        assistant_count += 1
                    # Early exit if we found enough content
                    if user_count >= 1 and assistant_count >= 1:
                        return True
                except json.JSONDecodeError:
                    continue
            return user_count > 0 or assistant_count > 0
    except Exception:
        return False


def convert_session(jsonl_file, md_file):
    """Convert Claude Code session JSONL to readable markdown."""

    jsonl_path = Path(jsonl_file)
    md_path = Path(md_file)

    if not jsonl_path.exists():
        print(f"Error: Input file not found: {jsonl_file}", file=sys.stderr)
        return False

    # Check for meaningful content first
    if not has_meaningful_content(jsonl_path):
        print(f"Skipping {jsonl_file}: No meaningful content (no user/assistant messages)", file=sys.stderr)
        return False

    try:
        entries = []
        with open(jsonl_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue

        if not entries:
            print("Error: No valid entries in session file", file=sys.stderr)
            return False

        with open(md_path, 'w', encoding='utf-8') as f_out:
            # Get session metadata from first entry
            first_entry = entries[0]
            session_id = first_entry.get('sessionId', 'unknown')

            # Find first timestamp
            first_ts = None
            for entry in entries:
                if 'timestamp' in entry:
                    first_ts = entry['timestamp']
                    break

            # Write header
            f_out.write(f"# Session Log\n\n")
            if first_ts:
                f_out.write(f"**Started:** {parse_timestamp(first_ts)}\n\n")
            f_out.write(f"**Source:** `{jsonl_path.name}`\n\n")
            f_out.write("---\n\n")

            # Track tool calls to pair with results
            pending_tools = {}

            for entry in entries:
                entry_type = entry.get('type', '')
                timestamp = entry.get('timestamp', '')
                time_str = parse_timestamp(timestamp) if timestamp else ''

                # User message
                if entry_type == 'user':
                    message = entry.get('message', {})
                    content = message.get('content', '')
                    text = extract_text_content(content)

                    # Skip empty or command-only messages
                    if text and not text.startswith('<command-'):
                        f_out.write(f"## 👤 User\n\n")
                        f_out.write(f"{text}\n\n")

                # Assistant message
                elif entry_type == 'assistant':
                    message = entry.get('message', {})
                    content = message.get('content', [])
                    text = extract_text_content(content)

                    if text and text.strip():
                        # Truncate very long responses
                        if len(text) > 8000:
                            text = text[:8000] + "\n\n*[... truncated ...]*"
                        f_out.write(f"## 🤖 Claude\n\n")
                        f_out.write(f"{text}\n\n")

                # Tool use
                elif entry_type == 'tool_use':
                    tool_name = entry.get('name', 'unknown')
                    tool_input = entry.get('input', {})
                    tool_id = entry.get('id', entry.get('uuid', ''))

                    f_out.write(f"## 🔧 Tool: {tool_name}\n\n")

                    # Show relevant input (file paths, commands, etc.)
                    if isinstance(tool_input, dict):
                        # Show key inputs without full content
                        summary_keys = ['command', 'file_path', 'pattern', 'query', 'url', 'description']
                        shown = []
                        for key in summary_keys:
                            if key in tool_input:
                                val = tool_input[key]
                                if isinstance(val, str) and len(val) > 200:
                                    val = val[:200] + "..."
                                shown.append(f"- **{key}:** `{val}`")
                        if shown:
                            f_out.write('\n'.join(shown) + "\n\n")
                        else:
                            # Fallback: show truncated JSON
                            input_str = json.dumps(tool_input, indent=2)
                            if len(input_str) > 500:
                                input_str = input_str[:500] + "\n..."
                            f_out.write(f"```json\n{input_str}\n```\n\n")

                    pending_tools[tool_id] = tool_name

                # Tool result
                elif entry_type == 'tool_result':
                    content = entry.get('content', '')
                    tool_id = entry.get('tool_use_id', '')

                    # Only show brief results
                    if content:
                        content_str = str(content)
                        if len(content_str) > 1000:
                            content_str = content_str[:1000] + "\n*[... truncated ...]*"
                        f_out.write(f"**Result:**\n```\n{content_str}\n```\n\n")

            f_out.write("\n---\n\n")
            f_out.write(f"*Converted from `{jsonl_path.name}`*\n")

        return True

    except Exception as e:
        print(f"Error converting session: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    if len(sys.argv) != 3:
        print("Usage: convert_session.py <input.jsonl> <output.md>")
        print("Example: convert_session.py session.jsonl session.md")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if convert_session(input_file, output_file):
        print(f"✓ Converted to {output_file}")
        sys.exit(0)
    else:
        print(f"✗ Conversion failed or skipped")
        sys.exit(1)


if __name__ == '__main__':
    main()
