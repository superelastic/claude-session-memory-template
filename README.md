# Session Memory — Claude Code Plugin

A Claude Code plugin that gives your projects persistent, git-versioned memory across sessions. Sessions travel with your repo.

## Install

```bash
# From the Claude Code CLI:
/plugin add superelastic/claude-session-memory-template
```

Then in your project:
```
/session-memory:setup
```

This creates the storage directories and adds instructions to your project's CLAUDE.md.

## What It Does

- **Automatic session archiving** — Sessions captured on exit via hooks, summarized on next start
- **Three-layer memory** — Raw logs → AI summaries → curated docs (investigations, decisions, references)
- **Git-versioned** — Memory lives in your repo, not a local database. Share context with your team.
- **Searchable** — Keyword search and optional semantic search via MCP tools
- **Pending queue** — Summaries created at session start (reliable) not session end (may be interrupted)

## How It Works

```
SessionEnd → archive-session.sh → .session_logs/pending/*.md (verbose)
SessionStart → agent hook → sessions/*.md (summarized) + delete pending
```

1. When a session ends, the hook archives the raw JSONL and converts it to a verbose markdown file in `.session_logs/pending/`
2. When the next session starts, the agent hook summarizes pending files into concise entries in `sessions/` and deletes the pending files
3. Context from recent sessions is automatically restored at startup

### Storage Directories (created in your project)

```
.session_logs/          Raw session archives + pending queue
  ├── pending/          Sessions awaiting summarization
  └── YYYY-MM/          Archived sessions by month
sessions/               AI-generated session summaries
docs/
  ├── investigations/   Hypothesis-driven research records
  ├── decisions/        Architecture Decision Records
  └── reference/        Methodologies and quick references
scratchpad.md           Current work tracking
```

## Commands

| Command | Description |
|---------|-------------|
| `/session-memory:setup` | Initialize session memory in a project |
| `/session-memory:startup` | Manually load context from previous sessions |
| `/session-memory:session-end` | Manually archive and summarize current session |
| `/session-memory:search <query>` | Search past sessions and documentation |

## MCP Tools

The plugin includes an MCP server that lets Claude autonomously search your session history:

| Tool | Description |
|------|-------------|
| `search_sessions` | Keyword search across sessions and docs |
| `semantic_search` | Vector similarity search (requires optional dependencies) |
| `read_document` | Read a specific session or document |
| `list_sessions` | List all sessions with optional pending filter |

## Semantic Search (Optional)

For vector-based search, install the optional dependencies:

```bash
pip install sentence-transformers torch
```

This enables the `semantic_search` MCP tool using `BAAI/bge-large-en-v1.5` embeddings locally — no API calls needed.

**First run downloads ~400MB model.** For faster but lower-quality results, you can edit `scripts/semantic_filter.py` to use `all-MiniLM-L6-v2` instead.

## Troubleshooting

### "No Claude sessions found for this project"

- Make sure you've run Claude Code in this project at least once
- On Windows, ensure you're running from WSL (not native Windows)
- Verify the project directory: `ls ~/.claude/projects/`

### "Permission denied" on scripts

```bash
chmod +x scripts/*.sh scripts/*.py
```

### Sessions not being archived

Check that hooks are enabled — the plugin's hooks should activate automatically when installed.

### Windows/WSL

Claude Code stores sessions in Linux paths only accessible from WSL. Keep projects in the WSL filesystem:

```
Good: /home/youruser/projects/my-project/
Bad:  /mnt/c/Users/youruser/projects/my-project/
```

## Contributing

Improvements and suggestions welcome! Please open an issue or PR.

## License

MIT License — Use freely in any project.
