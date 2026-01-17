#!/usr/bin/env python3
"""
convert_session.py - Convert Claude Code JSONL session to compact, complete markdown

Philosophy:
- User messages: Keep in FULL (what was asked)
- Claude responses: Keep in FULL (reasoning, decisions, explanations - this is the value)
- Tool calls: Summarize (tool name + key params, not full JSON)
- Tool results: Summarize outcome (not raw content)
- Metadata: Omit (timestamps, UUIDs, etc.)

Goal: 8MB JSONL → 20-50KB markdown with NO semantic loss
"""

import json
import sys
from pathlib import Path
from datetime import datetime


def extract_text_from_content(content):
    """Extract text from various content formats."""
    if isinstance(content, str):
        return content
    elif isinstance(content, list):
        texts = []
        for block in content:
            if isinstance(block, dict):
                if block.get('type') == 'text':
                    texts.append(block.get('text', ''))
                elif block.get('type') == 'thinking':
                    # Skip thinking blocks - internal reasoning
                    pass
                elif block.get('type') == 'tool_use':
                    # Tool uses are handled separately
                    pass
            elif isinstance(block, str):
                texts.append(block)
        return '\n'.join(texts)
    elif isinstance(content, dict):
        return content.get('text', '')
    return ''


def summarize_tool_call(tool_name, tool_input):
    """Create a concise summary of a tool call."""
    if not isinstance(tool_input, dict):
        return f"**{tool_name}**"

    # Tool-specific summarization
    if tool_name == 'Read':
        path = tool_input.get('file_path', 'unknown')
        return f"📖 Read `{path}`"

    elif tool_name == 'Write':
        path = tool_input.get('file_path', 'unknown')
        content = tool_input.get('content', '')
        lines = content.count('\n') + 1 if content else 0
        return f"✏️ Wrote `{path}` ({lines} lines)"

    elif tool_name == 'Edit':
        path = tool_input.get('file_path', 'unknown')
        old = tool_input.get('old_string', '')[:50]
        return f"✂️ Edited `{path}`"

    elif tool_name == 'Bash':
        cmd = tool_input.get('command', '')
        desc = tool_input.get('description', '')
        # Truncate long commands
        if len(cmd) > 100:
            cmd = cmd[:100] + '...'
        if desc:
            return f"💻 `{cmd}` — {desc}"
        return f"💻 `{cmd}`"

    elif tool_name == 'Glob':
        pattern = tool_input.get('pattern', '')
        path = tool_input.get('path', '.')
        return f"🔍 Glob `{pattern}` in `{path}`"

    elif tool_name == 'Grep':
        pattern = tool_input.get('pattern', '')
        path = tool_input.get('path', '.')
        return f"🔍 Grep `{pattern}` in `{path}`"

    elif tool_name == 'Task':
        desc = tool_input.get('description', '')
        agent = tool_input.get('subagent_type', 'agent')
        return f"🤖 Agent ({agent}): {desc}"

    elif tool_name == 'TodoWrite':
        todos = tool_input.get('todos', [])
        return f"📋 Updated todo list ({len(todos)} items)"

    elif tool_name == 'WebFetch':
        url = tool_input.get('url', '')
        return f"🌐 Fetched `{url}`"

    elif tool_name == 'WebSearch':
        query = tool_input.get('query', '')
        return f"🔎 Searched: {query}"

    elif tool_name == 'AskUserQuestion':
        questions = tool_input.get('questions', [])
        if questions:
            q = questions[0].get('question', '')[:100]
            return f"❓ Asked: {q}"
        return "❓ Asked user a question"

    else:
        # Generic fallback - show tool name and key params
        keys = list(tool_input.keys())[:3]
        params = ', '.join(f"{k}=..." for k in keys)
        return f"🔧 {tool_name}({params})"


def summarize_tool_result(content, tool_name=None):
    """Create a concise summary of a tool result."""
    if not content:
        return "(empty result)"

    content_str = str(content)

    # Check for common patterns
    if 'error' in content_str.lower()[:100]:
        # Extract first line of error
        first_line = content_str.split('\n')[0][:200]
        return f"❌ Error: {first_line}"

    # Count lines/length for context
    lines = content_str.count('\n')
    length = len(content_str)

    if lines > 10:
        # For long outputs, just summarize
        first_lines = '\n'.join(content_str.split('\n')[:3])
        return f"({lines} lines) {first_lines[:200]}..."
    elif length > 500:
        return f"{content_str[:300]}... ({length} chars)"
    else:
        return content_str


def has_meaningful_content(jsonl_path):
    """Check if session has actual user/assistant messages."""
    try:
        with open(jsonl_path, 'r', encoding='utf-8') as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    if entry.get('type') in ('user', 'assistant'):
                        return True
                except json.JSONDecodeError:
                    continue
        return False
    except Exception:
        return False


def convert_session(jsonl_file, md_file):
    """Convert Claude Code session JSONL to compact markdown."""

    jsonl_path = Path(jsonl_file)
    md_path = Path(md_file)

    if not jsonl_path.exists():
        print(f"Error: Input file not found: {jsonl_file}", file=sys.stderr)
        return False

    if not has_meaningful_content(jsonl_path):
        print(f"Skipping {jsonl_file}: No meaningful content", file=sys.stderr)
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
            return False

        # Get session date from first timestamp
        session_date = None
        for entry in entries:
            ts = entry.get('timestamp')
            if ts:
                try:
                    dt = datetime.fromisoformat(ts.replace('Z', '+00:00'))
                    session_date = dt.strftime('%Y-%m-%d %H:%M')
                    break
                except:
                    pass

        with open(md_path, 'w', encoding='utf-8') as f:
            # Minimal header
            f.write(f"# Session: {session_date or 'Unknown'}\n\n")

            # Track pending tool calls to match with results
            pending_tools = {}
            last_type = None

            for entry in entries:
                entry_type = entry.get('type', '')

                # User message - KEEP IN FULL
                if entry_type == 'user':
                    message = entry.get('message', {})
                    content = message.get('content', '')
                    text = extract_text_from_content(content)

                    # Skip empty or system messages
                    if not text or text.startswith('<command-'):
                        continue

                    # Clean up system reminders from user messages
                    if '<system-reminder>' in text:
                        # Extract just the user's actual message
                        import re
                        text = re.sub(r'<system-reminder>.*?</system-reminder>', '', text, flags=re.DOTALL)
                        text = text.strip()
                        if not text:
                            continue

                    f.write(f"## User\n\n{text}\n\n")
                    last_type = 'user'

                # Assistant message - KEEP IN FULL, extract nested tool calls
                elif entry_type == 'assistant':
                    message = entry.get('message', {})
                    content = message.get('content', [])
                    text = extract_text_from_content(content)

                    if text and text.strip():
                        # End any previous tool grouping
                        if last_type == 'tool':
                            f.write("\n")
                        f.write(f"## Claude\n\n{text}\n\n")
                        last_type = 'assistant'

                    # Extract tool calls from content array (Claude Code nests them here)
                    if isinstance(content, list):
                        tool_calls = [b for b in content
                                     if isinstance(b, dict) and b.get('type') == 'tool_use']
                        if tool_calls:
                            f.write("### Actions\n\n")
                            for tool in tool_calls:
                                tool_name = tool.get('name', 'unknown')
                                tool_input = tool.get('input', {})
                                tool_id = tool.get('id', '')
                                summary = summarize_tool_call(tool_name, tool_input)
                                f.write(f"- {summary}\n")
                                pending_tools[tool_id] = tool_name
                            last_type = 'tool'

                # Legacy: Tool use at top level (older JSONL format)
                elif entry_type == 'tool_use':
                    tool_name = entry.get('name', 'unknown')
                    tool_input = entry.get('input', {})
                    tool_id = entry.get('id', entry.get('uuid', ''))

                    summary = summarize_tool_call(tool_name, tool_input)

                    # Group consecutive tool calls
                    if last_type != 'tool':
                        f.write("### Actions\n\n")

                    f.write(f"- {summary}\n")
                    pending_tools[tool_id] = tool_name
                    last_type = 'tool'

                # Tool result - SUMMARIZE (only if error or notable)
                elif entry_type == 'tool_result':
                    # Skip - tool results are handled via pending_tools tracking
                    pass

                # Check for tool results nested in user messages (Claude Code format)
                elif entry_type == 'user':
                    # Already handled above, but check for tool_result in content
                    message = entry.get('message', {})
                    content = message.get('content', [])
                    if isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get('type') == 'tool_result':
                                tool_id = block.get('tool_use_id', '')
                                result_content = block.get('content', '')
                                tool_name = pending_tools.get(tool_id, 'unknown')
                                # Only include errors
                                content_str = str(result_content)
                                if 'error' in content_str.lower()[:200]:
                                    summary = summarize_tool_result(result_content, tool_name)
                                    if last_type == 'tool':
                                        f.write(f"  → {summary}\n")

                # End tool grouping with newline when transitioning away
                if last_type == 'tool' and entry_type not in ('assistant', 'tool_use', 'tool_result', 'user'):
                    f.write("\n")

            # Final newline if ended on tools
            if last_type == 'tool':
                f.write("\n")

        # Report compression ratio
        original_size = jsonl_path.stat().st_size
        new_size = md_path.stat().st_size
        ratio = original_size / new_size if new_size > 0 else 0

        return True

    except Exception as e:
        print(f"Error converting session: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def main():
    if len(sys.argv) != 3:
        print("Usage: convert_session.py <input.jsonl> <output.md>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]

    if convert_session(input_file, output_file):
        # Show compression stats
        in_size = Path(input_file).stat().st_size
        out_size = Path(output_file).stat().st_size
        ratio = in_size / out_size if out_size > 0 else 0
        print(f"✓ Converted: {in_size/1024:.1f}KB → {out_size/1024:.1f}KB ({ratio:.1f}x compression)")
        sys.exit(0)
    else:
        print(f"✗ Conversion failed or skipped")
        sys.exit(1)


if __name__ == '__main__':
    main()
