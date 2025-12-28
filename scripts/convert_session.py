#!/usr/bin/env python3
"""
convert_session.py - Convert Claude Code JSONL session to readable markdown

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
        return dt.strftime('%H:%M:%S')
    except:
        return ts_str

def convert_session(jsonl_file, md_file):
    """Convert Claude Code session JSONL to readable markdown."""
    
    jsonl_path = Path(jsonl_file)
    md_path = Path(md_file)
    
    if not jsonl_path.exists():
        print(f"Error: Input file not found: {jsonl_file}", file=sys.stderr)
        return False
    
    try:
        with open(jsonl_path, 'r', encoding='utf-8') as f_in, \
             open(md_path, 'w', encoding='utf-8') as f_out:
            
            # Parse first line to get session start time
            first_line = f_in.readline()
            if not first_line:
                print("Error: Empty session file", file=sys.stderr)
                return False
                
            first_entry = json.loads(first_line)
            session_time = first_entry.get('timestamp', 'Unknown')
            
            # Write header
            if session_time != 'Unknown':
                readable_time = parse_timestamp(session_time)
                f_out.write(f"# Session {readable_time}\n\n")
            else:
                f_out.write(f"# Session Log\n\n")
            
            f_out.write(f"Source: `{jsonl_path.name}`\n\n")
            f_out.write("---\n\n")
            
            # Reset to beginning
            f_in.seek(0)
            
            # Process each entry
            for line_num, line in enumerate(f_in, 1):
                try:
                    entry = json.loads(line)
                    
                    # Extract common fields
                    entry_type = entry.get('type', '')
                    timestamp = entry.get('timestamp', '')
                    time_str = parse_timestamp(timestamp) if timestamp else ''
                    
                    # Handle different entry types
                    if entry_type == 'user_message' or entry.get('role') == 'user':
                        content = entry.get('content', entry.get('text', ''))
                        f_out.write(f"## {time_str} User\n\n{content}\n\n")
                    
                    elif entry_type == 'assistant_message' or entry.get('role') == 'assistant':
                        content = entry.get('content', entry.get('text', ''))
                        # Truncate very long responses
                        if len(content) > 10000:
                            content = content[:10000] + "\n\n[... truncated ...]"
                        f_out.write(f"## {time_str} Claude\n\n{content}\n\n")
                    
                    elif entry_type == 'tool_use' or entry_type == 'tool_call':
                        tool_name = entry.get('name', entry.get('tool', 'unknown'))
                        tool_input = entry.get('input', entry.get('arguments', {}))
                        
                        f_out.write(f"## {time_str} Tool: {tool_name}\n\n")
                        
                        # Pretty print tool input
                        if isinstance(tool_input, dict):
                            f_out.write("```json\n")
                            f_out.write(json.dumps(tool_input, indent=2))
                            f_out.write("\n```\n\n")
                        else:
                            f_out.write(f"```\n{tool_input}\n```\n\n")
                    
                    elif entry_type == 'tool_result':
                        content = entry.get('content', '')
                        # Truncate large outputs
                        if len(str(content)) > 5000:
                            content = str(content)[:5000] + "\n[... truncated ...]"
                        
                        f_out.write(f"**Result:**\n```\n{content}\n```\n\n")
                    
                    elif entry_type == 'error':
                        error_msg = entry.get('error', entry.get('message', ''))
                        f_out.write(f"## {time_str} Error\n\n```\n{error_msg}\n```\n\n")
                
                except json.JSONDecodeError as e:
                    print(f"Warning: Skipping malformed line {line_num}: {e}", file=sys.stderr)
                    continue
                except Exception as e:
                    print(f"Warning: Error processing line {line_num}: {e}", file=sys.stderr)
                    continue
            
            f_out.write("\n---\n\n")
            f_out.write(f"*Converted from {jsonl_path.name}*\n")
        
        return True
        
    except Exception as e:
        print(f"Error converting session: {e}", file=sys.stderr)
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
        print(f"✗ Conversion failed")
        sys.exit(1)

if __name__ == '__main__':
    main()
